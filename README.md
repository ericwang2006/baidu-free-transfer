# baidu-free-transfer

百度网盘分享文件转存工具。免费用户单次转存存在 500 个文件的上限，本工具会自动拆分目录和文件批次，把分享内容完整转存到自己的网盘。

## 为什么会有这个工具

百度网盘对免费用户有单次转存 500 个文件的限制。当别人分享的文件夹包含大量文件时，手动分批转存非常麻烦，因此有了这个工具。

GitHub 上已有类似项目（如 [BaiduFilesTransfers_Pro](https://github.com/acheiii/BaiduFilesTransfers_Pro)），本项目重新实现了相关流程，并针对单目录文件数超限、分享列表分页等情况做了处理。

## 功能

- 支持 `https://pan.baidu.com/s/...` 和 `https://pan.baidu.com/share/init?surl=...` 两种分享链接
- 支持手动传入提取码，也可自动读取链接中的 `?pwd=xxxx`
- 支持通过 `-r` 指定转存到网盘的目标目录，目录不存在时自动创建
- 单个文件夹超过 500 个文件时，自动按每批 500 个拆分转存
- 文件分布在多个子目录时递归处理
- Cookie 可保存在 `config.yaml` 中重复使用
- 提供 Windows / Linux 单文件打包脚本

## 环境要求

- Python 3.7+
- [aiohttp](https://pypi.org/project/aiohttp/)
- [PyYAML](https://pypi.org/project/PyYAML/)

## 安装依赖

```bash
python3 -m pip install -r requirements.txt
```

Windows 下使用 `python` 代替 `python3`。

## 使用方法

以下命令需要在项目根目录执行（当前代码使用包内绝对导入）。

```bash
python3 -m baidutransfer <url> [-p <pwd>] [-r <目标目录>] [-C <cookie> | -c <config.yaml>]
```

参数说明：

| 参数 | 说明 |
| --- | --- |
| `url` | 百度网盘分享链接 |
| `-p, --password` | 分享提取码；链接中带 `?pwd=xxxx` 时可省略 |
| `-r, --root` | 转存到网盘的目标目录，如 `/我的资源/课程`；不填则转到网盘根目录 |
| `-C, --cookie` | 百度网盘 Cookie，优先级高于配置文件 |
| `-c, --config` | 配置文件路径，默认为当前目录下的 `config.yaml` |

### 配置文件

为了避免每次在命令行传 Cookie，可以创建 `config.yaml`：

```yaml
cookie: "BAIDUID=...; BDUSS=...; STOKEN=...;"
```

- 程序默认读取**当前工作目录**下的 `config.yaml`
- 使用 `-c /path/to/config.yaml` 可指定其他路径
- `-C` 参数优先于配置文件
- 配置文件不存在时程序会忽略它，此时必须通过 `-C` 提供 Cookie
- Cookie 属于登录凭证，`config.yaml` 已被 `.gitignore` 忽略，请勿提交到仓库

Cookie 的获取方式：在浏览器登录百度网盘，打开开发者工具，从网络请求的请求头中复制完整的 `Cookie`。

### 示例

以下链接和提取码均为示例，请替换为实际值。

```bash
# 提取码通过 -p 传入
python3 -m baidutransfer "https://pan.baidu.com/s/1yQ7wutp3m1XtEhsigf_X6A" -p 1234

# 提取码已包含在链接中
python3 -m baidutransfer "https://pan.baidu.com/s/1yQ7wutp3m1XtEhsigf_X6A?pwd=1234"

# 转存到指定目录
python3 -m baidutransfer "https://pan.baidu.com/s/1yQ7wutp3m1XtEhsigf_X6A?pwd=1234" -r /我的资源/课程

# 使用指定的配置文件
python3 -m baidutransfer "https://pan.baidu.com/s/1yQ7wutp3m1XtEhsigf_X6A" -c /path/to/config.yaml -r /目标目录
```

### 转存规则

程序会先尝试把整个分享目录作为一个整体转存。如果触发百度网盘的 500 文件上限（`errno 12`），会：

1. 目录列表触发上限时，把目录列表二分后递归转存；
2. 单个目录仍超限时，列出目录内容，按每批 500 个文件转存，并在控制台输出 `Fallback` 日志。

`errno 12` 也可能表示**网盘剩余空间不足**（接口返回 `剩余空间不足，无法转存`，且没有 `target_file_nums_limit` 字段）。这种情况无法通过拆分批次解决，程序会直接报告百度返回的错误信息，请清理空间后重试。

`/share/list` 接口每页最多返回 100 条记录，程序会自动翻页获取完整文件列表，不会因为文件较多而漏转。

## 打包为单文件程序

打包脚本会自动删除并重建 `.venv`、安装依赖，然后使用 PyInstaller 生成单文件程序。由于每次都会重建虚拟环境，构建过程需要保持网络可用。

### Windows

```bat
build.bat
```

生成：

```text
dist\baidutransfer.exe
```

### Linux

```bash
./build.sh
```

生成：

```text
dist/baidutransfer
```

- 系统存在 `strip` 时默认精简二进制；如需保留调试符号，使用 `STRIP=0 ./build.sh`
- Linux 二进制依赖构建机器的 glibc，如需兼容较老系统，请在较老的发行版或容器中构建
- 运行打包后的程序时，仍需保证当前目录有 `config.yaml`，或通过 `-c` 指定配置路径

## 注意事项

- 仅支持 `pan.baidu.com` 的分享链接
- Cookie 失效、链接失效或提取码错误都会导致转存失败，需要重新获取
- 转存使用 `ondup=newcopy`，同名文件不会覆盖，会生成副本
- 程序只读取小写的 `https_proxy` 环境变量作为代理
- 百度网盘接口可能调整；如果分享页解析失败，通常是 `apis.get_share_data()` 依赖的 `locals.mset(...)` 页面结构发生了变化

## 项目结构

```text
baidutransfer/
├── __main__.py   # 命令行入口、参数解析、配置加载
├── apis.py       # 百度网盘接口封装
├── transfer.py   # 转存流程、目录递归与超限拆分
└── utils.py      # HTTP 请求、日志和异常类型
```
