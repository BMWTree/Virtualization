import math

DEGREE = 2

file_path = './tests/test2.txt'
readable_output_file_path = './tests/readable2.txt'
mem_output_file_path = './tests/mem2.txt'

with open(file_path, 'r') as file:
    text = file.read()

# 将文本按行拆分
lines = text.split('\n')

# 创建一个空列表来存储 tree_id 和 level 的元组
tree_data = []

# 遍历每一行，提取 tree_id 和 level，并添加到列表中
for line in lines:
    if line.strip():  # 确保行不是空行
        parts = line.split(', ')
        tree_id = int(parts[0].split(': ')[1])
        level = int(parts[1].split(': ')[1])
        tree_data.append((tree_id, level))

# 按照 tree_id 排序列表
sorted_tree_data = sorted(tree_data, key=lambda x: x[0])

# 打印结果
for tree_id, level in sorted_tree_data:
    print(f"tree_id: {tree_id}, level: {level}")

# 找到 level 的最大值，max_level 就是 SRAM 的块数
max_tree_id = max(tree_data, key=lambda x: x[0])[0]
print(f"max_tree_id: {max_tree_id}")

# 找到 level 的最大值，max_level 就是 SRAM 的块数
max_level = max(tree_data, key=lambda x: x[1])[1]
print(f"max_level: {max_level}")

SRAM_NUM = int(input(f"请输入 SRAM 的块数(需要大于等于 max_level({max_level})): "))


start_addr_dict = {}

# start_addr of each level
start_addr = [0] * SRAM_NUM
for tree_id, level in sorted_tree_data:
    cur_level_size = 1
    for i in range(level):
        # tree 的第 i 层放在 SRAM 的 SRAM_id 中
        SRAM_id = (tree_id+i) % SRAM_NUM
        start_addr_dict[(tree_id, i)] = (SRAM_id, start_addr[SRAM_id])
        start_addr[SRAM_id] += cur_level_size
        cur_level_size *= DEGREE

max_SRAM_addr = max(start_addr)

SRAM_addr_bits = math.ceil(math.log2(max_SRAM_addr))
level_bits = math.ceil(math.log2(max_level))
tree_id_bits = math.ceil(math.log2(max_tree_id+1)) # tree_id 从 0 开始
SRAM_id_bits = math.ceil(math.log2(SRAM_NUM))

print(f"max_SRAM_addr: {max_SRAM_addr}")
print(f"max_level: {max_level} \n")

print(f"SRAM_addr_bits: {SRAM_addr_bits}")
print(f"level_bits: {level_bits}")
print(f"tree_id_bits: {tree_id_bits}")
print(f"SRAM_NUM_bits: {SRAM_id_bits}")



with open(readable_output_file_path, 'w') as output_file:
    for key, value in start_addr_dict.items():
        tree_id, i = key
        SRAM_id, start_address = value
        print(f"tree_id: {tree_id}, level: {i}, SRAM_id: {SRAM_id}, start_address: {start_address}", file=output_file)

with open(mem_output_file_path, 'w') as output_file:
    for tree_id in range(2 ** tree_id_bits):
        for level in range(2 ** level_bits):
            if (tree_id, level) in start_addr_dict:
                SRAM_id, start_address = start_addr_dict[(tree_id, level)]
                binary_SRAM_id = format(SRAM_id, f'0{SRAM_id_bits}b')
                binary_start_address  = format(start_address, f'0{SRAM_addr_bits}b')
            else:
                binary_SRAM_id = format((1 << SRAM_id_bits) - 1, f'0{SRAM_id_bits}b')
                binary_start_address  = format((1 << SRAM_addr_bits) - 1, f'0{SRAM_addr_bits}b')

            result_binary = binary_SRAM_id + binary_start_address
            print(f"{result_binary}", file=output_file)
            

print(f"输出已写入到文件: {readable_output_file_path, mem_output_file_path}")

