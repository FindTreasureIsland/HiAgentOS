#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="$0"
if [ -n "${BASH_SOURCE-}" ]; then
  SCRIPT_PATH="${BASH_SOURCE[0]}"
fi
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
PUBLIC_TEMPLATE_DIR="$SCRIPT_DIR/HiAgentsOS/public"
REMOTE_ARCHIVE_URL="https://github.com/FindTreasureIsland/HiAgentOS/archive/refs/heads/main.tar.gz"
TEMP_TEMPLATE_ROOT=""
COMMAND="install"
ROOT_DIR="$(pwd)"
ROOT_DIR_PROVIDED=0

case "${1:-}" in
  install|clean)
    COMMAND="$1"
    shift
    ;;
  -h|--help|help)
    cat <<EOF
Usage:
  $(basename "$0") [install] [server_root] [member ...]
  $(basename "$0") clean [server_root]

Commands:
  install   Create the HiAgentsOS server workspace and initialize Git repositories.
  clean     Remove all user directories under the HiAgentsOS server root.
EOF
    exit 0
    ;;
esac

if [ $# -gt 0 ]; then
  ROOT_DIR="$1"
  ROOT_DIR_PROVIDED=1
  shift
fi

MEMBERS=("$@")

print_banner() {
  cat <<'EOF'
 _   _ _    _                    _    ___  ____
| | | (_)  / \   __ _  ___ _ __ | |_ / _ \/ ___|
| |_| | | / _ \ / _` |/ _ \ '_ \| __| | | \___ \
|  _  | |/ ___ \ (_| |  __/ | | | |_| |_| |___) |
|_| |_|_/_/   \_\__, |\___|_| |_|\__|\___/|____/
                |___/
EOF
}

cleanup_temp_template() {
  if [ -n "$TEMP_TEMPLATE_ROOT" ] && [ -d "$TEMP_TEMPLATE_ROOT" ]; then
    rm -rf -- "$TEMP_TEMPLATE_ROOT"
  fi
}

trap cleanup_temp_template EXIT

prepare_public_template_dir() {
  if [ -d "$PUBLIC_TEMPLATE_DIR" ]; then
    return
  fi

  if ! command -v curl >/dev/null 2>&1; then
    printf "Error: curl is required to download the HiAgentOS template.\n" >&2
    exit 1
  fi

  if ! command -v tar >/dev/null 2>&1; then
    printf "Error: tar is required to extract the HiAgentOS template.\n" >&2
    exit 1
  fi

  TEMP_TEMPLATE_ROOT="$(mktemp -d)"

  if [ -n "${GITHUB_TOKEN:-}" ]; then
    curl -fsSL -H "Authorization: Bearer $GITHUB_TOKEN" "$REMOTE_ARCHIVE_URL" | tar -xz -C "$TEMP_TEMPLATE_ROOT"
  else
    curl -fsSL "$REMOTE_ARCHIVE_URL" | tar -xz -C "$TEMP_TEMPLATE_ROOT"
  fi

  PUBLIC_TEMPLATE_DIR="$TEMP_TEMPLATE_ROOT/HiAgentOS-main/HiAgentsOS/public"

  if [ ! -d "$PUBLIC_TEMPLATE_DIR" ]; then
    printf "Error: downloaded HiAgentOS template is missing public/.\n" >&2
    exit 1
  fi
}

prompt_for_root_dir() {
  local input_root

  printf "HiAgentsOS server root [%s]: " "$ROOT_DIR"
  read -r input_root

  if [ -n "$input_root" ]; then
    ROOT_DIR="$input_root"
  fi
}

prompt_for_members() {
  local input_members
  local normalized_members

  while [ ${#MEMBERS[@]} -eq 0 ]; do
    printf "User Agent names to %s (comma or space separated, for example: user1,user2): " "$COMMAND"
    read -r input_members

    normalized_members="${input_members//,/ }"
    # shellcheck disable=SC2206
    MEMBERS=($normalized_members)

    if [ ${#MEMBERS[@]} -eq 0 ]; then
      printf "Please enter at least one User Agent name.\n"
    fi
  done
}

validate_members() {
  local member

  for member in "${MEMBERS[@]}"; do
    if [[ "$member" == "public" ]]; then
      printf "Error: User Agent name cannot be 'public'.\n" >&2
      exit 1
    fi

    if [[ "$member" == "." || "$member" == ".." ]]; then
      printf "Error: User Agent name cannot be '%s'.\n" "$member" >&2
      exit 1
    fi

    if [[ "$member" == *"/"* ]]; then
      printf "Error: User Agent name cannot contain '/': %s\n" "$member" >&2
      exit 1
    fi

    if [[ "$member" == *"|"* ]]; then
      printf "Error: User Agent name cannot contain '|': %s\n" "$member" >&2
      exit 1
    fi
  done
}

normalize_install_root_dir() {
  mkdir -p "$ROOT_DIR"
  ROOT_DIR="$(cd "$ROOT_DIR" && pwd)"
}

normalize_existing_root_dir() {
  if [ ! -d "$ROOT_DIR" ]; then
    printf "Error: HiAgentsOS server root does not exist: %s\n" "$ROOT_DIR" >&2
    exit 1
  fi

  ROOT_DIR="$(cd "$ROOT_DIR" && pwd)"
}

if [ "$COMMAND" = "install" ] && [ "$ROOT_DIR_PROVIDED" -eq 0 ]; then
  prompt_for_root_dir
fi

if [ "$COMMAND" = "install" ]; then
  prompt_for_members
  validate_members
fi

if [ "$COMMAND" = "install" ]; then
  normalize_install_root_dir
else
  normalize_existing_root_dir
fi

print_banner

if [ "$COMMAND" = "install" ]; then
  prepare_public_template_dir
fi

write_file_if_missing() {
  local file_path="$1"
  local content="$2"

  if [ ! -f "$file_path" ]; then
    printf "%s\n" "$content" > "$file_path"
  fi
}

copy_public_seed_if_available() {
  local relative_path
  local source_path
  local target_path
  local target_public_dir

  if [ ! -d "$PUBLIC_TEMPLATE_DIR" ]; then
    return
  fi

  target_public_dir="$ROOT_DIR/public"

  if [ "$(cd "$PUBLIC_TEMPLATE_DIR" && pwd)" = "$(cd "$target_public_dir" 2>/dev/null && pwd || true)" ]; then
    return
  fi

  while IFS= read -r -d '' relative_path; do
    relative_path="${relative_path#./}"
    if [ "$relative_path" = "." ]; then
      continue
    fi

    source_path="$PUBLIC_TEMPLATE_DIR/$relative_path"
    target_path="$ROOT_DIR/public/$relative_path"
    mkdir -p "$target_path"
  done < <(
    cd "$PUBLIC_TEMPLATE_DIR"
    find . \
      -path './.git' -prune -o \
      -type d -print0
  )

  while IFS= read -r -d '' relative_path; do
    relative_path="${relative_path#./}"
    source_path="$PUBLIC_TEMPLATE_DIR/$relative_path"
    target_path="$ROOT_DIR/public/$relative_path"

    if [ ! -f "$target_path" ]; then
      mkdir -p "$(dirname "$target_path")"
      cp -p "$source_path" "$target_path"
    fi
  done < <(
    cd "$PUBLIC_TEMPLATE_DIR"
    find . \
      -path './.git' -prune -o \
      -name '.DS_Store' -prune -o \
      -name '*.swp' -prune -o \
      -type f -print0
  )
}

replace_marked_block() {
  local file_path="$1"
  local start_marker="$2"
  local end_marker="$3"
  local content_path="$4"
  local temp_path
  local in_block=0
  local replaced=0
  local line

  if ! grep -qF "$start_marker" "$file_path"; then
    return
  fi

  temp_path="$(mktemp)"

  while IFS= read -r line || [ -n "$line" ]; do
    if [ "$line" = "$start_marker" ]; then
      printf "%s\n" "$line"
      cat "$content_path"
      in_block=1
      replaced=1
      continue
    fi

    if [ "$line" = "$end_marker" ]; then
      in_block=0
      printf "%s\n" "$line"
      continue
    fi

    if [ "$in_block" -eq 0 ]; then
      printf "%s\n" "$line"
    fi
  done < "$file_path" > "$temp_path"

  if [ "$replaced" -eq 1 ]; then
    mv "$temp_path" "$file_path"
  else
    rm -f "$temp_path"
  fi
}

update_public_readme_members() {
  local readme_path="$ROOT_DIR/public/AGENTS.md"
  local member
  local members_table_path
  local profile_list_path

  if [ ! -f "$readme_path" ]; then
    return
  fi

  members_table_path="$(mktemp)"
  profile_list_path="$(mktemp)"

  if [ "${#MEMBERS[@]}" -gt 0 ]; then
    for member in "${MEMBERS[@]}"; do
      printf "| %s | %s | %s/%s | 待补充 |\n" "$member" "$member" "$ROOT_DIR" "$member" >> "$members_table_path"
      printf -- "- **%s**：%s 的专属助手\n" "$member" "$member" >> "$profile_list_path"
    done
  fi

  replace_marked_block \
    "$readme_path" \
    "<!-- HIAGENTSOS_MEMBERS_TABLE_START -->" \
    "<!-- HIAGENTSOS_MEMBERS_TABLE_END -->" \
    "$members_table_path"

  replace_marked_block \
    "$readme_path" \
    "<!-- HIAGENTSOS_PROFILE_LIST_START -->" \
    "<!-- HIAGENTSOS_PROFILE_LIST_END -->" \
    "$profile_list_path"

  rm -f "$members_table_path" "$profile_list_path"
}

create_public_server_workspace() {
  mkdir -p "$ROOT_DIR/public"

  copy_public_seed_if_available

  mkdir -p \
    "$ROOT_DIR/public/00文档模板" \
    "$ROOT_DIR/public/01规则文档" \
    "$ROOT_DIR/public/02会议管理/会前资料" \
    "$ROOT_DIR/public/02会议管理/会议纪要" \
    "$ROOT_DIR/public/02会议管理/周报" \
    "$ROOT_DIR/public/03项目计划" \
    "$ROOT_DIR/public/04问题跟踪" \
    "$ROOT_DIR/public/05市场项目跟踪" \
    "$ROOT_DIR/public/06业务看板" \
    "$ROOT_DIR/public/07决策记录"

  write_file_if_missing "$ROOT_DIR/public/01规则文档/HermesAgent协作规则.md" "# HermesAgent 协作规则

## 基本原则

- 公司主 Agent 绑定 \`public/\`。
- 个人 Agent 绑定自己的 \`{member_id}/\` 目录。
- 个人 Agent 可读取 \`public/\` 和自己的成员目录。
- 个人 Agent 默认不得读取其他成员目录。
- 公司主 Agent 可读取各成员目录，用于公司级汇总。
- 文档是 Agent 之间的协作协议，Git 是同步和权限边界。

## 目录绑定

| Agent 类型 | 绑定目录 | 可读 | 可写 |
|---|---|---|---|
| 公司主 Agent | public/ | public/ + 授权成员目录 | public/ |
| 个人 Agent | {member_id}/ | public/ + 自己的 {member_id}/ | 自己的 {member_id}/ |
| 系统业务 Agent | public/ 指定业务目录 | 授权目录 | 授权目录 |
"

  update_public_readme_members
}

create_member_server_workspace() {
  local member_id="$1"

  mkdir -p \
    "$ROOT_DIR/$member_id/00规则文档" \
    "$ROOT_DIR/$member_id/01个人OKR" \
    "$ROOT_DIR/$member_id/02工作计划/工作归档" \
    "$ROOT_DIR/$member_id/03个人文档"

  write_file_if_missing "$ROOT_DIR/$member_id/README.md" "# $member_id 工作空间

本目录为成员个人工作空间，对应个人 HermesAgent。

## 目录说明

- 00规则文档：个人规则和偏好
- 01个人OKR：年度/季度 OKR
- 02工作计划：每日工作计划和复盘
- 03个人文档：个人文档和业务沉淀

## Agent 约定

- 默认读取：public/、$member_id/
- 默认写入：$member_id/
- 默认不得读取其他成员目录
"

  write_file_if_missing "$ROOT_DIR/$member_id/00规则文档/HermesAgent个人规则.md" "# HermesAgent 个人规则

## 工作空间

- 绑定目录：\`$member_id/\`
- 可读目录：\`public/\`、\`$member_id/\`
- 可写目录：\`$member_id/\`

## 常用工作流

- 创建每日工作计划
- 更新每日复盘
- 整理市场机会
- 沉淀解决方案
- 记录项目调研
"
}

init_git_repo_if_needed() {
  local repo_dir="$1"

  if ! command -v git >/dev/null 2>&1; then
    printf "Warning: git command not found, skipped repository initialization for %s\n" "$repo_dir" >&2
    return
  fi

  if [ -d "$repo_dir/.git" ]; then
    return
  fi

  git -C "$repo_dir" init -q
}

init_server_repos() {
  local member

  init_git_repo_if_needed "$ROOT_DIR/public"

  for member in "${MEMBERS[@]}"; do
    init_git_repo_if_needed "$ROOT_DIR/$member"
  done
}

clean_member_server_workspaces() {
  local member_dir
  local member_name
  local removed_count=0

  shopt -s nullglob

  for member_dir in "$ROOT_DIR"/*; do
    if [ ! -d "$member_dir" ]; then
      continue
    fi

    member_name="$(basename "$member_dir")"

    if [ "$member_name" = "public" ]; then
      continue
    fi

    rm -rf -- "$member_dir"
    printf "Removed user directory: %s\n" "$member_dir"
    removed_count=$((removed_count + 1))
  done

  shopt -u nullglob

  if [ "$removed_count" -eq 0 ]; then
    printf "No user directories found under: %s\n" "$ROOT_DIR"
  fi
}

if [ "$COMMAND" = "clean" ]; then
  clean_member_server_workspaces
  MEMBERS=()
  update_public_readme_members

  cat <<EOF
HiAgentsOS server user directories cleaned.

Server root:
  $ROOT_DIR

Updated:
  public/AGENTS.md
EOF
  exit 0
fi

create_public_server_workspace

for member in "${MEMBERS[@]}"; do
  create_member_server_workspace "$member"
done

init_server_repos

cat <<EOF
HiAgentsOS server template installed.

Server root:
  $ROOT_DIR

Members:
$(printf '  - %s\n' "${MEMBERS[@]}")

Initialized Git repositories:
  - public
$(printf '  - %s\n' "${MEMBERS[@]}")

Next step:
  Review public/01规则文档/HermesAgent协作规则.md
EOF
