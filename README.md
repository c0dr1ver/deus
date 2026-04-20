# deus
Disk Extension USage

📄 Description

🇬🇧 English

A lightweight Bash utility that scans a directory and analyzes disk usage for files by extension.

The tool calculates:

Total number of files
Total disk space used
Aggregated size and file count per top-level directory (depth=1)

Designed for quick diagnostics and disk usage analysis without multiple filesystem scans. Uses a single find pass for optimal performance.

🇨🇳 中文 (Chinese)

一个轻量级的 Bash 工具，用于扫描目录并分析指定文件扩展名的磁盘使用情况。

该工具可以计算：

文件总数量
总占用空间
每个一级子目录（depth=1）的文件数量和空间占用

采用单次 find 扫描，性能高效，适用于快速磁盘使用分析和故障排查。

🇷🇺 Русский

Лёгкая утилита на Bash для анализа использования дискового пространства по файлам с заданным расширением.

Инструмент рассчитывает:

Общее количество файлов
Общий занимаемый объём
Размер и количество файлов по папкам первого уровня (depth=1)

Использует один проход find, что делает его быстрым и эффективным для диагностики и анализа дискового пространства.

```markdown
## Example

```bash
$ ./deus.sh
Enter the absolute path to the folder: /home/user/Downloads
Enter the file extension (e.g. mp3, pdf): pdf

Total files: 1106
Total size : 1.27 GB

Size           Files    Folder
759.96 MB      576      Telegram Desktop
533.53 MB      517      ./ (root)
6.96 MB        13       RDP
