#! /usr/bin/perl
#

use Getopt::Std;
use Data::Dumper;
use File::Basename;
use Socket;

# THIS FILE SHOULD BE A SYMLINK, so it can find its modules and libs ...
BEGIN {
	my $EXECDIR="./";
	my $SYMLINK=readlink($0);
	if ($SYMLINK ne '') {
		# Oh! In that case I know my REAL directory with all my modules, and stuff
		$EXECDIR=dirname($SYMLINK);
		push (@INC,$EXECDIR);
	} else {
		push (@INC,"./");
	}
}

use config;
use solaris_isc_option_names;
use dhcp_common;

sub dhtadm_usage {
	#print "dhtadm: Must specify one of 'C', 'A', 'M', 'D', 'R', or 'P'\n";
	print "dhtadm: Must specify one of 'A', 'M', 'D', or 'P'\n";
	print "\n";
	print "dhtadm [-g] (options)\n";
	print "\n";
	print "Where (options) is one of:\n";
	print "\n";
	#print "-C              Create the dhcptab\n";
	#print "\n";
	print "-A              Add symbol or macro. Sub-options:\n";
	print "                { -s (symbol name) | -m (macro name) } -d (definition)\n";
	print "\n";
	print "-M              Modify symbol or macro. Sub-options:\n";
	print "                -s (old symbol name) {-n (new name) | -d (definition)}\n";
	print "                                Or\n";
	print "                -m (old macro name) {-n (new name) | -d (definition) | -e (symbol = value)}\n";
	print "\n";
	print "-D              Delete symbol or macro definition. Sub-options:\n";
	print "                -s ( symbol name ) | -m ( macro name )\n";
	print "\n";
	#print "-R              Remove the dhcptab\n";
	#print "\n";
	print "-P              Display the dhcptab\n";
	print "\n";
}


### Main ###
getopts('CAMDRPd:m:s:e:n:gl:', \%option);

#make sure there is only one of C A M D R P options!!!
my $cap_options_counter=0;
foreach my $o ('C','A','M','D','R','P') {
	$cap_options_counter++ if ($option{$o});
}

if ($cap_options_counter != 1) {
	dhtadm_usage();
	exit 1;
}

$debug=$option{l};

if ($ARGV[0] ne '') { $dhcpd4_conf_file=$ARGV[0]; } 			# define your own dhcpd4.conf file for testing ...

open(LOCK,">/tmp/dhcpd4.conf.lck") or die "Cannot create lockfile \"/tmp/dhcpd4.conf.lck\" :$!\n";
flock(LOCK,2);

open(DHCPD4CONF,"$dhcpd4_conf_file");
@dhcp_data=<DHCPD4CONF>;
close DHCPD4CONF;

@dhcp_data=beautify(@dhcp_data);
push @dhcp_data,"\n";				# add dummy empty line to data_array

my ($ret_hash,$dummy)=&read_dhcpd4conf(0);
$dhcp_hash=$ret_hash;

### MAIN ###

if ($option{A}) {
	&dhtadm_A;
}

if ($option{D}) {
	&dhtadm_D;
}

if ($option{M}) {
	&dhtadm_M;
}
if ($option{P}) {
	&dhtadm_P;
}

if (! $option{P}) {
	print "=" x 80 , "\n" if ($debug);
	print Dumper($dhcp_hash),"\n" if ($debug);
	print "=" x 80 , "\n" if ($debug);

	if ($debug) {		#debug, write to STDOUT
		open(FILE,">&STDOUT") or die "Can't dup STDOUT: $!";
		write_dhcpd4conf(0,$dhcp_hash,"");
		close FILE;
	} else {
		&save_old_config_file;
		open(FILE,">$dhcpd4_conf_file") or die "Cannot open \"$dhcpd4_conf_file\" for write: $!\n";
		write_dhcpd4conf(0,$dhcp_hash,"");
		close FILE;
	}
}
close LOCK;

if ($option{g}) {
	my $dhcpd_status=&check_service_state('silent');
	# $dhcpd_status = 0 ==> not running ................
	# $dhcpd_status = 1 ==> running ................
	# so if it was NOT running, it was for a reason, and we will NOT restart it!
	my $os=`uname -s`;chomp $os;
	if ($os eq "SunOS") {
		system('svcadm restart svc:/network/dhcp/server:ipv4') if ($dhcpd_status);
	} else {
		# assume linux ...
		# first find out where the start service script is:
		# as for now I've seen 2 services called:
		# dhcpd and isc-dhcp-server
		my $cmd='';
		my $out='';
		my $found=0;

		# where is service ?
		$service="/sbin/service";
		if (-x "/sbin/service") {
			$service="/sbin/service";
		} elsif (-x "/usr/sbin/service") {
			$service="/usr/sbin/service";
		} else {
			print "Cannot find \"service\" command\n";
			exit 1;
		}

		foreach my $t ('dhcpd','isc-dhcp-server') {
			$cmd="$service $t 2>&1";
			$out=`$cmd`;
			chomp $out;
			if ($out =~ /usage/i) {
				$found++;
				last;
			}
		}
		if ($found) {
			my ($u,$service_script,$o)=split /\s+/, $out;
			$cmd=$service_script . " restart";
			system($cmd) if ($dhcpd_status);
		}
	}
}

my $dhcpd_status=&check_service_state();





