# HiAgentOS

```text
 _   _ _    _                    _    ___  ____
| | | (_)  / \   __ _  ___ _ __ | |_ / _ \/ ___|
| |_| | | / _ \ / _` |/ _ \ '_ \| __| | | \___ \
|  _  | |/ ___ \ (_| |  __/ | | | |_| |_| |___) |
|_| |_|_/_/   \_\__, |\___|_| |_|\__|\___/|____/
                |___/
```

HiAgentOS is a lightweight workspace template for organizing AI-assisted team work. It provides a shared `public/` knowledge space, per-user workspaces, Agent collaboration rules, document templates, and a server-side installer for initializing and cleaning a HiAgentOS workspace.

## What It Includes

- `install_hiagentsos.sh`: server-side installer and cleaner.
- `HiAgentsOS/public/AGENTS.md`: AI assistant operating guide and collaboration rules.
- `HiAgentsOS/public/00文档模板/`: reusable document templates for daily plans, OKRs, meetings, project plans, and opportunity tracking.
- `HiAgentsOS/public/01规则文档/`: shared rules for work plans, directory structure, weekly reports, daily retrospectives, and HermesAgent collaboration.
- `HiAgentsOS/public/02会议管理/`: meeting preparation, meeting minutes, and weekly report archives.
- `HiAgentsOS/public/03项目计划/`: project planning documents.
- `HiAgentsOS/public/04问题跟踪/`: issue, risk, and defect tracking.
- `HiAgentsOS/public/05市场项目跟踪/`: market opportunity and customer follow-up tracking.
- `HiAgentsOS/public/06业务看板/`: business dashboards and status summaries.
- `HiAgentsOS/public/07决策记录/`: decision records and follow-up actions.

## Usage

Run directly with `curl`:

```bash
curl -fsSL https://raw.githubusercontent.com/FindTreasureIsland/HiAgentOS/main/install_hiagentsos.sh | bash -s -- /path/to/server
```

Or use the explicit install command:

```bash
curl -fsSL https://raw.githubusercontent.com/FindTreasureIsland/HiAgentOS/main/install_hiagentsos.sh | bash -s -- install /path/to/server
```

The installer will prompt for User Agent names during setup.

Clean user directories with `curl`:

```bash
curl -fsSL https://raw.githubusercontent.com/FindTreasureIsland/HiAgentOS/main/install_hiagentsos.sh | bash -s -- clean /path/to/server
```

When the installer is run through `curl`, it automatically downloads the `HiAgentsOS/public` template from the GitHub repository before creating the workspace.

Install a HiAgentOS server workspace:

```bash
./install_hiagentsos.sh /path/to/server
```

Or use the explicit command:

```bash
./install_hiagentsos.sh install /path/to/server
```

This creates:

```text
/path/to/server/
├── public/
├── alice/
└── bob/
```

The installer also initializes separate Git repositories for `public/` and each user directory, and updates `public/AGENTS.md` with the configured members.

Clean all user directories from a server workspace:

```bash
./install_hiagentsos.sh clean /path/to/server
```

The `clean` command removes first-level user directories under the server root, keeps `public/`, and clears the member table and Profile list in `public/AGENTS.md`.

## Workspace Model

HiAgentOS separates shared and personal work:

- `public/` is the shared company or team space. It contains templates, rules, project coordination documents, dashboards, and decision records.
- `{member}/` is a personal Agent workspace. It contains personal rules, OKRs, work plans, archives, and personal documents.
- `public/AGENTS.md` is the main Agent-facing rule document. Agents should read it first and write the rules into HermesAgent's `Rule.md` for long-term rule memory.

## Notes

- User names cannot be `public`, `.`, `..`, or contain `/` or `|`.
- Template seed files are copied without overwriting existing files.
- Generated workspaces keep separate Git histories for `public/` and each member directory.
