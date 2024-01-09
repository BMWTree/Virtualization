import argparse
import matplotlib.pyplot as plt

parser = argparse.ArgumentParser(description='Read data from file and print a PrettyTable.')
parser.add_argument('input_file_path', type=str, help='Path to the input file')

args = parser.parse_args()

xlabel = 'Pop cnt'

ylabel = 'Priority'

def get_pfmap_file_name(input_file_name):
    # 查找 ".output" 的位置
    dot_pos = input_file_name.find(".output")

    assert dot_pos != -1, ".output not found in input file name"

    # 用 ".trace" 替换 ".output"
    output_file_name = input_file_name[:dot_pos] + ".pfmap" + input_file_name[dot_pos + 7:]

    return output_file_name

def get_refoutput_file_name(input_file_name):
    # 查找 ".output" 的位置
    dot_pos = input_file_name.find(".output")

    assert dot_pos != -1, ".output not found in input file name"

    # 用 ".trace" 替换 ".output"
    output_file_name = input_file_name[:dot_pos] + ".ref" + input_file_name[dot_pos + 7:]

    return output_file_name

def get_fig_file_name(input_file_name):
    # 查找 ".output" 的位置
    dot_pos = input_file_name.find(".output")

    assert dot_pos != -1, ".output not found in input file name"

    # 用 ".trace" 替换 ".output"
    output_file_name = input_file_name[:dot_pos] + ".png" + input_file_name[dot_pos + 7:]

    return output_file_name

def get_reffig_file_name(input_file_name):
    # 查找 ".output" 的位置
    dot_pos = input_file_name.find(".output")

    assert dot_pos != -1, ".output not found in input file name"

    # 用 ".trace" 替换 ".output"
    output_file_name = input_file_name[:dot_pos] + ".ref.png" + input_file_name[dot_pos + 7:]

    return output_file_name

pfmap_file_path = get_pfmap_file_name(args.input_file_path)
output_file_path = args.input_file_path+'.txt'
refoutput_file_path = get_refoutput_file_name(args.input_file_path)
fig_file_path = get_fig_file_name(args.input_file_path)
reffig_file_path = get_reffig_file_name(args.input_file_path)


with open(pfmap_file_path, 'r') as file:
    lines = file.readlines()

pfmap = {}

# get pfmap
for line in lines:

    parts = line.strip().split(', ')
    
    meta_value = int(parts[0].split(':')[1])
    flow_value = int(parts[1].split(':')[1])
    
    pfmap[meta_value] = flow_value


def draw_fig(output_file_path, fig_file_path):

    plt.clf()
    plt.figure()

    diff_cyc = {}
    push_cyc = {}

    with open(output_file_path, 'r') as file:
        lines = file.readlines()

    for line in lines:
        parts = line.strip().split(', ')
        
        # 提取 meta 和 push_cyc/pop_cyc 的值
        meta_value = int(parts[0].split(':')[1])
        cyc_type, cyc_value = parts[1].split(':')
        cyc_value = int(cyc_value)

        if cyc_type == 'push_cyc':
            diff_cyc[meta_value] = cyc_value
            push_cyc[meta_value] = cyc_value
        elif cyc_type == 'pop_cyc':
            diff_cyc[meta_value] = cyc_value
            # diff_cyc[meta_value] = cyc_value - diff_cyc[meta_value]
        else:
            assert(0)

    flow_diff_cyc_lists = {}

    for meta_value, diff_value in diff_cyc.items():
        flow_value = pfmap.get(meta_value)
        if flow_value not in flow_diff_cyc_lists:
            flow_diff_cyc_lists[flow_value] = []
        flow_diff_cyc_lists[flow_value].append(diff_value)

    flow_push_cyc_lists = {}

    for meta_value, push_value in push_cyc.items():
        flow_value = pfmap.get(meta_value)
        if flow_value not in flow_push_cyc_lists:
            flow_push_cyc_lists[flow_value] = []
        flow_push_cyc_lists[flow_value].append(push_value)

    for flow_value in flow_diff_cyc_lists.keys():
        flow_diff_cyc_list = flow_diff_cyc_lists.get(flow_value)
        flow_push_cyc_list = flow_push_cyc_lists.get(flow_value)
        
        if flow_push_cyc_list is not None and flow_diff_cyc_list is not None:
            plt.scatter(flow_push_cyc_list, flow_diff_cyc_list, s=0.4,label=f'Flow {flow_value}')

    # 设置图表标题和坐标轴标签
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)

    # 添加图例
    plt.legend()

    # 保存图表为图片文件（例如PNG）
    plt.savefig(fig_file_path, dpi=1200)

    plt.clf()
    plt.figure()

    # 绘制折线图
    for flow_value in flow_diff_cyc_lists.keys():
        flow_diff_cyc_list = flow_diff_cyc_lists.get(flow_value)
        flow_push_cyc_list = flow_push_cyc_lists.get(flow_value)

        flow_diff_cyc_list = flow_diff_cyc_list[:50]
        flow_push_cyc_list = flow_push_cyc_list[:50]
        
        if flow_push_cyc_list is not None and flow_diff_cyc_list is not None:
            plt.scatter(flow_push_cyc_list, flow_diff_cyc_list, s=3,label=f'Flow {flow_value}')

    # 设置图表标题和坐标轴标签
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)

    # 添加图例
    plt.legend()

    # 保存图表为图片文件（例如PNG）
    plt.savefig(fig_file_path+'.start.png', dpi=500)




draw_fig(output_file_path, fig_file_path)
draw_fig(refoutput_file_path, reffig_file_path)


