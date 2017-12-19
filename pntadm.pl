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

sub pntadm_usage {
	#### direct output from solaris pntadm ..
	print "$0: Must specify one of 'C', 'A', 'M', 'D', 'R', 'P', 'L' or 'B'.\n";
	print "\n";
	### no -r, -p -u in ISC DHCP !!!!!
	### print "$0 [-r (resource)] [-p (path)] [-u (uninterpreted data)] (options) [(network ip)]\n";
	print "$0 (options) [(network ip)]\n";
	print "\n";
	print "Where (options) is one of:\n";
	print "\n";
	print " -C                     Create the named table\n";
	print "\n";
	print " -A (client ip or name) Add client entry. Sub-options:\n";
	print "                        [-c (comment)]\n";
	print "                        [-e (lease expiration)]\n";
	print "                        [-f (flags)]\n";
	print "                        [-i (client identifier) | -I -i (mac address)\n";
	print "                        [-u (extra client identifier -dhcp option 61-)\n";
	print "                        [-m (dhcptab macro reference)]\n";
	print "\n";
	print " -M (client ip or name) Modify client entry. Sub-options:\n";
	print "                        [-c (new comment)]\n";
	print "                        [-e (new lease expiration)]\n";
	print "                        [-f (new flags)]\n";
	print "                        [-i (new client identifier) | -I -i (new mac address)\n";
	print "                        [-u (extra client identifier -dhcp option 61-)\n";
	print "                        [-m (new dhcptab macro reference)]\n";
	print "\n";
	print " -D (client ip or name or Mac Address -see sub options-) Delete client entry.\n";
	print "                        [-z]    use MAC address for entry instead.\n";
	print "                        -zD 01AABBCCDDEEFF or -zD aa:bb:cc:dd:ee:ff";
	print "\n";
	print " -R                     Remove the named table\n";
	print "\n";
	print " -P                     Display the named table. Sub-options:\n";
	print "                        [-v]    Display lease time in full format.\n";
	print "                        [-x]    Display lease time in raw format.\n";
	print "\n";
	print " -L                     List the configured DHCP networks\n";
	print "                        [-v]    Lists networks with short netmask.\n";
	print "\n";
	### no -B option in ISC DHCP
	### print " -B [batchfile]         Run command in batch input mode. Sub-options:\n";
	### print "                        [-v]    Output commands as they are processed.\n";
	### print "\n";
	print " The network ip argument is required for all options except -L \n";
	print "\n";
}


### Main ###
getopts('A:M:c:e:f:i:u:Im:D:zCRPvxLh:s:n:yd:', \%option);

#make sure there is only one of C A M D R P L options!!!
my $cap_options_counter=0;
foreach my $o ('C','A','M','D','R','P','L') {
	$cap_options_counter++ if ($option{$o});
}

if ($cap_options_counter != 1) {
	pntadm_usage();
	exit;
}

if ($ARGV[0] eq '' and ! $option{L}) {
	pntadm_usage();
	exit;
}

$network=$ARGV[0];
if ($ARGV[1] ne '') { $dhcpd4_conf_file=$ARGV[1]; } 			# define your own dhcpd4.conf file for testing ...

$debug=$option{d};

# create a lock file here (well, actually never create the file ;-)
open(LOCK,">/tmp/dhcpd4.conf.lck") or die "Cannot create lockfile \"/tmp/dhcpd4.conf.lck\" :$!\n";
flock(LOCK,2);

open(DHCPD4CONF,"$dhcpd4_conf_file");
@dhcp_data=<DHCPD4CONF>;
close DHCPD4CONF;

# %dhcp_hash;
@dhcp_data=beautify(@dhcp_data);
push @dhcp_data,"\n";				# add dummy empty line to data_array

my ($ret_hash,$dummy)=&read_dhcpd4conf(0);
$dhcp_hash=$ret_hash;

# print Dumper($dhcp_hash),"\n" if ($debug);

if ($option{L}) {
	&pntadm_L;
	exit;
}

my $network_found_flag=0;

if ($option{C}) {
	my ($nw,$bitmask)=split /\//,$network;
	$nw=&trim($nw);
	$bitmask=&trim($bitmask);
	if ($nw eq '' or $bitmask eq '') {
		print STDERR "invalid argument, use: <network>/<bitmask>\n";
		exit;
	}
	
	if (! &check_ip($nw)) {
		exit 1;
	}

	if ($bitmask <= 0 or $bitmask >= 32) {
		print "Bitmask must be >1 and < 32 \n";
		exit 1;
	}
	&pntadm_C(&convert_ip2dec($nw),$bitmask);
	$network_found_flag++;
}

### the rest of all commands need an entry in the dhcpd4.conf for the network
foreach my $n (keys %{$dhcp_hash->{subnet}}) {
	if ($n eq $network) {
		$network_found_flag++;
		last;
	}
}
	
if (! $network_found_flag) {
	print STDERR "Network $network does not exist.\n";
	exit 1;
}

if ($option{P}) {
	&pntadm_P($network);
	my $dhcpd_status=&check_service_state();
	exit;
}

if ($option{R}) {
	if (! &check_ip($network)) {
		exit 1;
	}
	&pntadm_R($network);
}

if ($option{D}) {
	&pntadm_D($network);
}

if ($option{A}) {
	&pntadm_A($network);
}

if ($option{M}) {
	&pntadm_M($network);
}


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
close LOCK;
my $dhcpd_status=&check_service_state();
