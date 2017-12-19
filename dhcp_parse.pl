#! /usr/bin/perl
#

use Getopt::Long;
use Data::Dumper;
use File::Basename;

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

use solaris_isc_option_names;
use dhcp_common;


### Main ###
my $status=0;
GetOptions (
	# "length=i" => \$length, 		# numeric
	# "file=s" => \$data, 			# string
	"status" => \$status 			# flag
	) or die ("Error in command line arguments\n");

if ($ARGV[0] eq '') {
	$dhcpd4_conf_file="/etc/inet/dhcpd4.conf";
} else {
	$dhcpd4_conf_file=$ARGV[0];
}

open(DHCPD4CONF,"$dhcpd4_conf_file");
@dhcp_data=<DHCPD4CONF>;
close DHCPD4CONF;

# %dhcp_hash;
@dhcp_data=beautify(@dhcp_data);
push @dhcp_data,"\n";
my ($ret_hash,$dummy)=&read_dhcpd4conf(0);
$dhcp_hash=$ret_hash;

### if $status then report the leases with omshell
if ($status) {
	omshell_status("10.137.232.0");
	exit;
}

##### delete record with hardware ethernet 00:14:4F:8D:20:74
# delete_from_host('hardware ethernet','00:14:4F:8D:20:74');
# delete_from_host('fixed-address','10.137.234.80');

#### add record with hostname=paul, mac aa:bb:cc:dd:ee:ff, ip=10.173.250.1
#$dhcp_hash->{subnet}->{'10.173.0.0'}->{'host'}->{'paul'}->{'hardware ethernet'}->[0]='aa:bb:cc:dd:ee:ff';
# or
#push @{$dhcp_hash->{subnet}->{'10.173.0.0'}->{'host'}->{'paul'}->{'hardware ethernet'}},'aa:bb:cc:dd:ee:ff';
#$dhcp_hash->{subnet}->{'10.173.0.0'}->{'host'}->{'paul'}->{'fixed-address'}->[0]='10.173.250.1';
# or
#push @{$dhcp_hash->{subnet}->{'10.173.0.0'}->{'host'}->{'paul'}->{'fixed-address'}},'10.173.250.1';

print "\$dhcp_hash:", Dumper($dhcp_hash),"\n";

my $level=0;
my $out=*STDOUT;
write_dhcpd4conf($out,$level,$dhcp_hash,"");
