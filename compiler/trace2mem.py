import argparse

TREE_NUM_BITS = 2
IDLECYCLE_BITS = 8
PTW = 24
MTW = 2

ROM_SIZE = 16384


TOTAL_WIDTH = max(IDLECYCLE_BITS, (PTW+TREE_NUM_BITS+MTW+PTW)) + 2

idlecycle_padding = (IDLECYCLE_BITS < (PTW+TREE_NUM_BITS+MTW+PTW))

padding_bits = abs(IDLECYCLE_BITS - (PTW+TREE_NUM_BITS+MTW+PTW))

width_dict = {'type': 2, 'priority1': PTW, 'tree_id': TREE_NUM_BITS, 'meta': MTW, 'priority0': PTW, 'idle_cycle': IDLECYCLE_BITS}

# 设置命令行参数
parser = argparse.ArgumentParser(description='Read data from file and print a PrettyTable.')
parser.add_argument('input_file_path', type=str, help='Path to the input file')

# 解析命令行参数
args = parser.parse_args()

def get_trace_file_name(input_file_name):
    # 查找 ".output" 的位置
    dot_pos = input_file_name.find(".output")

    assert dot_pos != -1, ".output not found in input file name"

    # 用 ".trace" 替换 ".output"
    output_file_name = input_file_name[:dot_pos] + ".trace" + input_file_name[dot_pos + 7:]

    return output_file_name

readable_file = get_trace_file_name(args.input_file_path)
mem_file = get_trace_file_name(args.input_file_path)+'.mem'

# 打开文件并读取除去第一行的剩余部分
with open(readable_file, 'r') as file:
    lines = file.readlines() 

# 初始化一个空的二进制字符串
binary_result = ""

with open(mem_file, 'w') as output_file:
    # 遍历每一行
    for line in lines:
        # 将每行按逗号分割
        items = line.split(',')

        # 遍历每个项，提取数字值并转换为指定位数的二进制
        for item in items:
            # 分割每个项，以冒号为界
            parts = item.split(':')
            
            name = parts[0].strip()
            value = int(parts[1].strip())
            
            assert(name in width_dict)
            # 将数字值转换为指定位数的二进制，并拼接到结果字符串中
            binary_result += format(value, f'0{width_dict[name]}b')

            # padding
            if name == 'type' and ((idlecycle_padding and value == 0) or (not idlecycle_padding and value == 1)):
                binary_result += format(0, f'0{padding_bits}b')
            if name == 'type' and value == 2:
                binary_result += format(0, f'0{TOTAL_WIDTH - 2}b')

        # 输出结果
        output_file.write(binary_result + '\n')  # 添加换行符以分隔每一行
        binary_result = ""

    for i in range(ROM_SIZE - len(lines)) :
        # 输出结果
        output_file.write(format(0, f'0{TOTAL_WIDTH}b') + '\n')  # 添加换行符以分隔每一行

print('generate memfile successfully!')