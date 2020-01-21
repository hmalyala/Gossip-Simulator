# DOS Project 1


Gopichand Kommineni         UFID 0305-5523
Hemanth Kumar Malyala       UFID 6348-5914
We implemented 

# Gossip Algorithm

The Gossip algorithm involves the
following:
• Starting: A participant(actor) it told/sent a rumor(fact) by the main process
• Step: Each actor selects a random neighbor and tells it the rumor
• Termination: Each actor keeps track of rumors and how many times it has
heard the rumor. It stops transmitting once it has heard the rumor 10 times
(10 is arbitrary, you can play with other numbers or other stopping criteria).



Push-Sum algorithm for sum computation:
• State: Each actor Ai maintains two quantities: s and w. Initially, s = xi = i (that
is actor number i has value i, play with other distribution if you so desire) and
w = 1.
• Starting: Ask one of the actors to start from the main process.
• Receive: Messages sent and received are pairs of the form (s, w). Upon
receive, an actor should add received pair to its own corresponding values.
Upon receive, each actor selects a random neighbor and sends it a message.
• Send: When sending a message to another actor, half of s and w is kept by
the sending actor and half is placed in the message.
• Sum estimate: At any given moment of time, the sum estimate is s/w where
s and w are the current values of an actor.
• Termination: If an actor ratio s/w did not change more than 10-10 in 3
consecutive rounds the actor terminates. WARNING: the values s and w
independently never converge, only the ratio does.



Topologies: The actual network topology plays a critical role in the dissemination
speed of Gossip protocols. As part of this project you have to experiment with
various topologies. The topology determines who is considered a neighbor in the
above algorithms.
