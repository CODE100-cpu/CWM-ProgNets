chatgpt was used to obtain information about operation (How can tcpdump restrict messages to 100 packets) and integrity of results(Is server and client energy similar error or reality?)

## Simple Measurements
***Q: How did the power change as the Rasberry Pi is powered on?***

The power starts from 0w and steadily increases to 5W(peak fluctuation) as all the internal programs of the Rasberry Pi is activated, and falls back to 4.58W

***Q:Does the Rasberry Pi power consumption reaches a steady state value?***

The Rasberry Pi reaches a quasi-stable value of approximately 4.6W with occasional fluctuation to 4.8W. The fluctuation should be due to the period of internal program running on the system (viewable in htop). The total energy consumed is 0.02Wh

## Network activity

***Q: what is the approximate frequency of messaging?***

I used tcpdump -c 100 to obtain events and calculated the time spent by the operation.

However, after tcpdump is executed a message saying that 121 packets are actually received with 21 of them dumped by the filter. As we define event of the network as either a packet received or transmitted. The total number of events is $$121(received) + 121(sent) = 242$$
The total time spent was 34.058s.
Thus the frequency is 7.1 events/s

***Q: Does the creation of user-generated network traffic impact the energy consumption of the Raspberry Pi?*** 

Observing the UCB tester shows that the power consumption is increased to around 5.6W during the flooding experiment with the Rasberry Pi as the sender (total energy consumption of 0.6Wh)

***Q: Is it more expensive from an energy  standpoint for the Raspberry Pi to send than to  receive?***

When the Pi was the receiver during flooding experiment, the total energy consumption was 0.5Wh, significantly lower than the when it was the sender.
Sending is obviously going to consume more energy as transmitting signal is giving kinetic energy to signal and would consume more energy than detecting the presence of a signal.

***Q:What is the maximum impact the network might have on the energy consumption of the Raspberry Pi?***

For the first iperf experiment,  the energy consumption was the same of 0.03Wh(power of around 5.4W) for when the Rasberry Pi was the server and the client. The difference compared to the above discussion about receiver and sender is accounted for by 1.The float point digit of the UCB tester is limited, if we can show another digit then we can see the difference. 2.Being a server requires running extra programs than when the Rasberry Pi was just the receiver, therefore more energy consumption.

In practice, client consumes more energy than the server due to traffic load and congestion because of packet retransmission.

For the second iperf experiment, the energy consumption was similar to the first experiment(both of 0.03Wh). This is due to the fact that 57micro seconds of delay(the original rx-usecs) of interruption of CPU is very negligible and 0s doesn't make much difference. However, if we had set the delay time higher, such as 1s, as the CPU gets interrupted less frequently, it spends more time on processing rather than being interrupted, we would expect the CPU to do more work and therefore increase in power consumption

## CPU stress test
***Q: How was the result?***

The power consumption during the test was 6.2W(energy consumption of 0.034W), this is maximum power consumption possible.
We see that all previously power consumption was strictly less than this power consumption.

## Theoretical Experiments
***Q:what was the carbon footprint?***

The location chosen was PJM(USA): 396g/kwH.
For the flooding experiment:
sending : $$ 0.05Wh * 396g/kWh = 1.98 * 10^{-2} g$$
receiving: 
$$ 0.06Wh * 396g/kWh = 2.4 * 10^{-2} g$$

For the first iperf experiment:
receiving and sending: 
$$ 0.03Wh * 396g/kWh = 1.19 * 10^{-2} g$$


For the second iperf experiment:
receiving and sending: 
$$ 0.03Wh * 396g/kWh = 1.19 * 10^{-2} g$$

For the cpu experiment:
$$ 0.035Wh * 396g/kWh = 1.39 * 10^{-2} g$$

The total carbon footprint is therefore:
$$0.1045g$$

***Q: What if all Things connected to the Internet were Raspberry Pi’s?***

Assuming average power of 5.4W

The yearly energy consumption is 
$$ 8760h/year * 5.4W = 47.3kWh/year $$

Assuming global average carbon intensity = 0.475kg/kwh

$$ CF = 0.475 * 30 * 10^9 * 47.304 = 6.74 * 10^{11}kg$$

The number is very significant and would cause significant global warming. 

However, this is not a very accurate estimation as 
1.Not all devices consume similar energy as Rasberry Pi, a switch consumes less while super computers consume much more.
2.We assumed an all-year-round constant energy consumption, which is not true.
3.In  reality we have other energy consuming factors such as traffic loads and congestions.

The total internet carbon footprint estimation for this year by chatgpt is $9*10^{11}kg$, and we see that our situation is very different to this number.



