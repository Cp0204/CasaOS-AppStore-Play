import glob
import ruamel.yaml

def modify_yaml(file_path):
    yaml = ruamel.yaml.YAML()
    yaml.preserve_quotes = True
    yaml.width = 2 ** 32
    # 读取docker-compose.yml文件内容
    with open(file_path, 'r', encoding='utf-8') as file:
        data = yaml.load(file)
    # 修改数据
    app_name = data['name']
    app_name = app_name.replace("-arm", "")
    app_name_arch = app_name + '-arm'
    data['name'] = app_name_arch
    data['services'][app_name_arch] = data['services'].pop(app_name)
    data['services'][app_name_arch]['container_name'] = app_name_arch
    data['x-casaos']['main'] = app_name_arch
    # 写回docker-compose.yml文件
    with open(file_path, 'w', encoding='utf-8') as file:
        yaml.dump(data, file)

# 获取匹配的文件列表
files = glob.glob('./Apps_arm/*/docker-compose.yml')

# 对每个文件进行修改
for file_path in files:
    print(file_path)
    modify_yaml(file_path)
