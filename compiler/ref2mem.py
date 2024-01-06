import argparse

binary_width = 24

ROM_SIZE = 8192

# 设置命令行参数
parser = argparse.ArgumentParser(description='Read data from file and print a PrettyTable.')
parser.add_argument('input_file_path', type=str, help='Path to the input file')

# 解析命令行参数
args = parser.parse_args()

def get_ref_file_name(input_file_name):
    # 查找 ".output" 的位置
    dot_pos = input_file_name.find(".output")

    assert dot_pos != -1, ".output not found in input file name"

    # 用 ".trace" 替换 ".output"
    output_file_name = input_file_name[:dot_pos] + ".ref"

    return output_file_name

def convert_to_binary(input_file, output_file, binary_width):
    with open(input_file, 'r') as infile:
        numbers = infile.read().splitlines()

    binary_numbers = [format(int(num), f'0{binary_width}b') for num in numbers]

    with open(output_file, 'w') as outfile:
        outfile.write('\n'.join(binary_numbers))
        outfile.write('\n')
        for i in range(ROM_SIZE - len(numbers)) :
            outfile.write(format(0, f'0{binary_width}b') + '\n')  # 添加换行符以分隔每一行

# 使用示例：将输入文件中的数字转换为8位二进制，并写入输出文件
convert_to_binary(get_ref_file_name(args.input_file_path), get_ref_file_name(args.input_file_path)+'.mem', binary_width)
