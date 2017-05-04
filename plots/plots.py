import getopt
import glob
import json
import matplotlib
import matplotlib.pyplot as plt
import numpy as np
import sys

def get_args():
    args, remaining = getopt.getopt(sys.argv[1:], 'd:')
    if len(args) == 0:
        print('This requires a directory')
        exit()
    return args[0][1]

def get_time(module, rows):
    if "time_per_op_usec" in rows[0][module]:
        return [row[module]["time_per_op_usec"] for row in rows]
    else:
        return []

def parse_results(file):
    with open(file, 'r') as f:
        data = json.loads(f.read())
        results = data["results"]
        operations = [x["operations"] for x in results]

        stdlib_times = get_time("stdlib", results)
        vial_times = get_time("vial", results)
        phoenix_times = get_time("phoenix", results)

        result = {
                'stdlib': stdlib_times,
                'vial': vial_times,
                'phoenix': phoenix_times,
                'operations': operations
        }
        return result

def normalise(results, module):
    data = [result[module] for result in results]
    return np.mean(np.array(data), axis=0)

def label_for(string):
    parts = string.split(" ")
    max_length = len(max(parts, key=len))
    padding = max_length + 4
    return "\n".join([part.center(padding) for part in parts])

def plot_times(axes, module, operations, times):
    if times.any():
        axis = axes.plot(operations, times)

        xpos = operations[-1]
        ypos = times[-1]
        label = label_for(module)
        color = axis[-1].get_color()
        axes.text(xpos, ypos, label, color=color)
    else:
        return None


def main():
    matplotlib.rcParams.update({'font.size': 12})
    directory  = get_args()
    data_files = glob.glob(f"{directory}/*.json")
    results = [parse_results(file) for file in data_files]

    operations = normalise(results, 'operations')

    stdlib_times = normalise(results, 'stdlib')
    vial_times = normalise(results, 'vial')
    phoenix_times = normalise(results, 'phoenix')

    fig, axes = plt.subplots()

    axes.set_title("Time taken to perform N operations")

    axes.spines["bottom"].set_alpha(0.2)
    axes.spines["left"].set_alpha(0.2)

    axes.spines["top"].set_visible(False)
    axes.spines["right"].set_visible(False)

    axes.yaxis.grid()

    for line in axes.get_ygridlines():
        line.set_linestyle('dashed')
        line.set_alpha(0.6)

    axes.tick_params(axis="both", which="both", bottom="off", top="off",
                    labelbottom="on", left="off", right="off", labelleft="on")

    plot_times(axes, 'Existing CRDT', operations, phoenix_times)
    plot_times(axes, 'Specialised CRDT', operations, vial_times)
    plot_times(axes, 'StdLib', operations, stdlib_times)

    axes.set_xlabel('Operations (thousands)')
    axes.set_ylabel('Time (nanoseconds)')

    x1,x2,y1,y2 = axes.axis()

    axes.set_ylim(0, y2)
    axes.set_xlim(min(operations), max(operations))

    plt.show()

if __name__ == "__main__":
    main()
