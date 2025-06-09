# !/usr/bin/python3
import numpy as np
import matplotlib.pyplot as plt

# parameters to modify
filename="ping00001p.txt"
label='RRT'
xlabel = 'Time(s)'
ylabel = 'CDF'
title='CDF of RRT (0.0001s)'
fig_name='00001RRT.png'
bins=100 #adjust the number of bins to your plot


t = np.loadtxt(filename, delimiter=" ", dtype="float")
data = t[:, 1]
data = np.sort(data)
cdf = np.arange(len(data)) / len(data)
plt.plot(data, cdf, label=label)  # Plot some data on the (implicit) axes.
#Comment the line above and uncomment the line below to plot a CDF
#plt.hist(t[:,1], bins, density=True, histtype='step', cumulative=True, label=label)
plt.xlabel(xlabel)
plt.ylabel(ylabel)
plt.title(title)
plt.legend()
plt.savefig(fig_name)
plt.show()
