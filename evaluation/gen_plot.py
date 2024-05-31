import os
import subprocess
import sys

def install_and_import(package):
    try:
        __import__(package)
    except ImportError:
        subprocess.check_call([sys.executable, '-m', 'pip', 'install', package])
        __import__(package)
# Set libraries
install_and_import('matplotlib')
install_and_import('pandas')
install_and_import('seaborn')
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns

def set_style():
    # This sets reasonable defaults for font size for
    # a figure that will go in a paper
    sns.set_context("paper")
    
    sns.set(rc={'figure.figsize':(11.7, 5.27)})
    
    # Set the font to be serif, rather than sans
    sns.set(font='serif')
    
    # Make the background white, and specify the
    # specific font family
    sns.set_style("white", {
        "font.family": "serif",
        "font.serif": ["Times", "Palatino", "serif"]
    })
    
    sns.set_theme(style="ticks", palette="pastel")
    
def parse_res(file, benchmark="not_provided"):
    try:
        with open(file, 'r') as f:
            lines = f.read().split("\n")
    except:
        print(f"{file} not found")
        return pd.DataFrame()
        
    data = []
    for line in lines:
        if line:
            try:
                script, time = line.split()
                if float(time) == 0.0:
                    raise Exception()
                sname = script.replace(".sh:", "")
                data.append([f"{sname}_{benchmark}", sname, float(time)])
            except:
                print(f"Skipping {line}")
    
    df = pd.DataFrame(data, columns=["uid", "benchname", "exec_time"])
    df = df.set_index("uid")
    return df

# folder = 'no_checksum'

def average_dfs(dfs):
    df = pd.concat(dfs)
    df = df.groupby('bench_name').mean()
    return df

def get_summary_per_mode(benchmarks, modes):
    # Returns a list of lists where each sublist contains all modes results for a benchmarks
    all_benchs = []
    for benchmark in benchmarks:
        dfs = {}
        for mode in modes:
            df = parse_res(f'{benchmark}/outputs/{mode}/{benchmark}.res', benchmark)
            dfs[mode] = df
        all_benchs.append((benchmark, dfs))
        
    summary_per_mode = {}
    for mode in modes:
        summary = []
        for benchmark, dfs in all_benchs:
            dfs[mode]['benchmark'] = benchmark
            summary.append(dfs[mode])

        new_df = pd.concat(summary, axis = 0)
        new_df['mode'] = mode
        summary_per_mode[mode] = new_df
    return summary_per_mode


def remap_labels(df):
    remap_mode = {'hadoopstreaming': "Hadoop-streaming", 'pash': "PaSh", 'dish': "DiSh", "naive": "Naive", "base": "Base", "optimized": "Optimized"}
    df['mode'] = df['mode'].map(remap_mode)
    remap_benchmark = {'nlp': 'NLP', 'oneliners': 'Classics', 'unix50': 'Unix50', 'covid-mts': 'COVID-mts'}
    df['benchmark'] = df['benchmark'].replace(remap_benchmark)
    df['benchname'] = df['benchname'].replace({ 'temp-analytics': 'AvgTemp' })
    return df
    

def get_speedup_df(summary_per_mode):
    dfs = []
    for mode in summary_per_mode:
        if mode == 'bash':
            continue
        summary_per_mode[mode]['speedup'] = summary_per_mode['bash']['exec_time']/summary_per_mode[mode]['exec_time']
        summary_per_mode[mode].dropna()
        dfs.append(summary_per_mode[mode])
    summary_df = pd.concat(dfs, axis = 0)
    summary_df.dropna()
    
    return remap_labels(summary_df)


def print_stats():
    def print_mode_stats(df, baseline_mode, mode):
        speedup_df = pd.DataFrame()
        speedup_df['speedup'] = df[baseline_mode]['exec_time']/df[mode]['exec_time']
        speedup_df.dropna()
        with open(stats_file, 'a') as file:
            file.write(f"{mode} speedup over {baseline_mode} stats:\n Mean {speedup_df['speedup'].mean()}, Max {speedup_df['speedup'].max()}, Min  {speedup_df['speedup'].min()}\n")

    benchmarks = [
            # "oneliners",
            # "unix50",
            # "nlp",
            "covid-mts",
            # "max-temp"
    ]

    modes = [
            "bash",
            "pash", 
            "dish", 
            # "naive",
            # "base",
            # "optimized"
    ]
    summary_per_mode = get_summary_per_mode(benchmarks, modes)
    summary_df = pd.concat(summary_per_mode, axis = 1)
    # summary_df.to_csv("benchmarks.csv")

    stats_file = f"{PLOT_DIR}/stats.txt"

    with open(stats_file, 'w') as file:
        file.write(f"Printing stats:\n")
    print_mode_stats(summary_per_mode, "bash", "pash")
    print_mode_stats(summary_per_mode, "bash", "dish")
    # print_mode_stats(summary_per_mode, "bash", "naive")
    # print_mode_stats(summary_per_mode, "bash", "base")
    # print_mode_stats(summary_per_mode, "bash", "optimized")

def print_speedup_boxplot():
    def boxplot(df, x, y, savefig=None, ax=None):
        f = sns.boxplot(data=df, x = x, y = y, hue="mode", ax=ax)
        f.set(yscale='log')
        plt.legend(loc='upper left')
        f.set(xlabel='Benchmark')
        f.axhline(1, ls='--')
        if savefig:
            plt.savefig(savefig)
    benchmarks = [
            # "oneliners",
            # "unix50",
            # "nlp",
            "covid-mts",
            # "max-temp"
    ]

    modes = [
            "bash",
            "pash", 
            "dish", 
            # "naive",
            # "base",
            # "optimized"
    ]
    summary_per_mode = get_summary_per_mode(benchmarks, modes)
    df1 = get_speedup_df(summary_per_mode)
    print(df1)
    boxplot(df1, x='benchmark', y='speedup', savefig=f"${PLOT_DIR}/distr_boxplot.pdf")


def print_speedup_barplot():
    def speedup_barplot(df, x, y, savefig=None, ax=None):
        f = sns.barplot(data=df, x=x, y = y, hue="mode", ax=ax)
        f.set(xlabel='Benchmark')
        f.axhline(1, ls='--')
        plt.legend(loc='upper left')
        plt.xticks(rotation=45)
        plt.tight_layout()
        f.set(yscale='log')
        if savefig:
            plt.savefig(savefig)
    benchmarks = [
                # "oneliners",
                # "unix50",
                # "nlp",
                "covid-mts",
                # "max-temp"
    ]

    modes = [
            "bash",
            "pash", 
            "dish", 
            # "naive",
            # "base",
            # "optimized"
    ]
    summary_per_mode = get_summary_per_mode(benchmarks, modes)
    df2 = get_speedup_df(summary_per_mode)
    speedup_barplot(df2, 'benchname', 'speedup', f"{PLOT_DIR}/par_vs_distr_barplot.pdf")


# Create plot folder if do not exist already
PLOT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "plots")
os.makedirs(PLOT_DIR, exist_ok=True)


# Set style
set_style()

print_stats()

# print_speedup_boxplot()

print_speedup_barplot()

# TODO: we probably want to have a plot showing all the faulty cases
