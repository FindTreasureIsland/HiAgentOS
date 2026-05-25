# HermesAgent 协作规则

## 基本原则

- 公司主 Agent 绑定 `public/`。
- 个人 Agent 绑定自己的 `{member_id}/` 目录。
- 个人 Agent 可读取 `public/` 和自己的成员目录。
- 个人 Agent 默认不得读取其他成员目录。
- 公司主 Agent 可读取各成员目录，用于公司级汇总。
- 文档是 Agent 之间的协作协议，Git 是同步和权限边界。

## 目录绑定

| Agent 类型 | 绑定目录 | 可读 | 可写 |
|---|---|---|---|
| 公司主 Agent | public/ | public/ + 授权成员目录 | public/ |
| 个人 Agent | {member_id}/ | public/ + 自己的 {member_id}/ | 自己的 {member_id}/ |
| 系统业务 Agent | public/ 指定业务目录 | 授权目录 | 授权目录 |

