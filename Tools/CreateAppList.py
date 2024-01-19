import glob
import os
import yaml
import re

# 获取匹配的文件列表
compose_files = glob.glob('./Apps/*/docker-compose.yml')

# 初始化Markdown表格
markdown_table = "| Icon | AppName | Description |\n"
markdown_table += "|:----:|---------|-------------|\n"

# 读取并解析docker-compose.yml文件，提取字段，并添加到Markdown表格
for compose_file in compose_files:
    with open(compose_file, 'r', encoding='utf-8') as f:
        try:
            data = yaml.safe_load(f)
            app_name = os.path.basename(os.path.dirname(compose_file))
            icon = data.get('x-casaos', {}).get('icon', '')
            title = data.get('x-casaos', {}).get('title', {}).get('en_us', '')
            description1 = data.get('x-casaos', {}).get('description', {}).get('en_us', '')
            description2 = data.get('x-casaos', {}).get('description', {}).get('zh_cn', '')
            if (description1==description2):
                description = description1
            elif (description1==""):
                description = description2
            else:
                description = f"{description1}<br>{description2}"

            markdown_table += f"| ![{title}]({icon}) | [{title}](./Apps/{app_name}) | {description} |\n"
        except Exception as e:
            print(f"Error parsing {compose_file}: {e}")


# 将Markdown表格写入AppList.md文件
#with open('AppList.md', 'w', encoding='utf-8') as readme:
#    readme.write(markdown_table)

# 替换README.md文件内容
file_path = 'README.md'
with open(file_path, 'r', encoding='utf-8') as file:
    content = file.read()
new_content = re.sub(rf'(## App List / 应用列表)([\w\W]*)', '## App List / 应用列表\n\n' + markdown_table , content)
with open(file_path, 'w', encoding='utf-8') as file:
    file.write(new_content)

print("已生成")
