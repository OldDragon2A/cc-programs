cc-programs
===========

ComputerCraft Programs for Turtles and Computers

MBE - Murder Box Extreme
------------------------

This is a self configuring program designed to the startup for MBE computers/turtles.
It ripple boots neighboring computers and turtles and determines where it should attack and drop without individual configuration.
Through rednet, the entire collective can be controlled from any computer running MBE or through specific messages.

control - Manual Turtle Controller
----------------------------------

This is a simple interface to some of the turtle's movement and digging functions. 

mine - Efficient Miner
----------------------

    usage: mine [options] -- <x> <y> <z>
    
      -f level  set minimum fuel level
      -l file   log verbose oupput to file
      -n        no torches
      -s space  set the torch spacing
      -t        wait for torches if out
      -v level  enable verbose output
      -w        wait for torches

A mining program with an efficient pattern for clearing areas.  Works best with vertical areas.
Should be placed inside the corner of the area to be mined.  The '--' is used to prevent negative
numbers in the dimensions from being mistaken for options.  The slot layout is described inside the
program and can be changed with the variables at the top.  If you are not using an ender chest, make
sure to put a chest behind the starting location as that is where it will wait to make drop offs.
