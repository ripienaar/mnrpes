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

![Basic Overview](https://raw.github.com/ripienaar/mnrpes/master/docs/mnrpes-overview.jpg)

*This is still not complete, check back for more information later*

Shortcomings?
-------------

This isn't some magical make-nagios-suck-less thing, you still need to
configure every service to receive the Passive Checks in Nagios else it will
just discard the Passive Results for non existing hosts or services.

Your MCollective identifies need to match up with what you have called your
hosts in Nagios as it will simply use the identities for host names in the
Passive Results.

If your NRPE check command is called *check_load* then this system will submit
a passive check to the *load* service.

The scheduler isn't aware of your Nagios config so if you add a check
somewhere you should also add it to the checks file.  The core idea is that we
find that many hosts have common checks across batches of them, this system
will optimise and scale the gathering of those results.

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

The output handling is handled using plugins.  By default it uses the *nagios*
output as described here but there are some others, see the *output* directory,
you can choose a different output handler:

    plugin.mnrpes.processors = stdout

The processors can be a list like:

    plugin.mnrpes.processors = stdout,nagios

Which means both plugins will get the data.

For best results you would want to run MCollective  2.1.1 at least and one
of the new Discovery Plugins that does discovery against a local cache like
MongoDB or PuppetDB.

This way you will not be doing costly discoveries against the network all the
time and get consistant host lists.

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
