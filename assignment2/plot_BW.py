# !/usr/bin/python3
import numpy as np
import matplotlib.pyplot as plt

# parameters to modify
filename="b.txt"
label='Bandwidth'
xlabel = 'Time(s)'
ylabel = 'BandWidth(Mbits/s)'
title = 'Bandwidth'
fig_name='Bandwidth.png'
bins=100 #adjust the number of bins to your plot


t = np.loadtxt(filename, delimiter=" ", dtype="float")
t = t[0:10]
x = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

plt.plot(x, t, label=label)  # Plot some data on the (implicit) axes.
#Comment the line above and uncomment the line below to plot a CDF
#plt.hist(t[:,1], bins, density=True, histtype='step', cumulative=True, label=label)
plt.xlabel(xlabel)
plt.ylabel(ylabel)
plt.title(title)
plt.legend()
plt.savefig(fig_name)
plt.show()
