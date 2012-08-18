What?
=====

Nagios provides a scheduler that runs check on a regular basis and write those
check results into it's database.  This is called Active Checks.

It has a second mode called Passive Checks where an external system performs
the checks and writes the result to it's command file.

This is a system that uses MCollective and the Rufus scheduler to build a
distributed async scheduler and checker for Nagios based on the Passive mode.
This approach will scale better and perform all checks of a specific plugin at
more or less the same time thanks to the basic nature of MCollectives
broadcast system.

All communications between the scheduler, nodes and receivers are secured
using your MCollective security infrastructure and authorization to run checks
are done using the MCollective Authorization system.

*This is still not complete, check back for more information later*

Configuration?
--------------

You need MCollective fully working with the NRPE 2.2 or newer plugin deployed.
This system uses MCollective libraries for configuration, logging, security
and communications.

Depending on your MCollective security setup you might need to run the
scheduler and the receiver using the same *client.cfg* sharing properties like
SSL certificates and such.

Apart from the basic MCollective setup you can also set the following:

    plugin.mnrpes.nagios.command_file = /var/spool/nagios/rw/nagios.cmd
    plugin.mnrpes.reply_queue = /queue/mcollective.nagios_passive_results

This affects where your Nagios *command_file* file is and what Stomp
destination is being used to transport check results.

Adding Checks?
--------------
Checks live in a simple file, an example can be seen below:

    nrpe "check_swap", "1m"
    nrpe "check_load", "1m"
    nrpe "check_bacula_main", "6h", "bacula::node"

Here we create 3 checks with different intervals, the last one has a
MCollective filter applied, the filter syntax matches that of the *-W*
argument to the MCollective command line.

The scheduler takes a *--checks* option that is the path to this file

Who?
----

R.I.Pienaar / rip@devco.net / @ripienaar / http://devco.net
