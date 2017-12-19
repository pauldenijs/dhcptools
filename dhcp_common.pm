sub trim {
	my ($str)=@_;
	$str=~s/^\s+//;
	$str=~s/\s+$//;
	return($str);
}

sub beautify {
	# you can't imagine how people make a mess of their files ;-)
	(@old_dhcp_data)=@_;
	my @new_dhcp_data;

	my $eol_flag=0;
	foreach my $b (@old_dhcp_data) {
		chomp $b;
		$b=trim($b);
		# I guess we want to keep the '=' but have spaces around it ...
		$b=~s/\s+/ /g;
		$b=~s/\s+=\s+/ = /g;

		if ($b =~ /(^.*)({)(.*)(};)/ and $b !~ /^#/) {
			# line with { blabla };  Is actually a whole value ....
			push @new_dhcp_data,$b;
		} elsif ($b =~ /(^.*)({)(.*)(})/ and $b !~ /^#/) {
			# line with { blabla } split up as :
			$s=$1 . $2;
			push @new_dhcp_data,$s;
			foreach my $l (split /;/, $3) {
				$l=trim($l);
				next if ($l =~ /^$/);
				if ($l=~/^#/) {
					# oh crap!, the previous pushed data in the array had a comment!
					# fix it!
					my $last_line=pop @new_dhcp_data;
					push @new_dhcp_data, "$last_line $l";
				} else {
					push @new_dhcp_data,"$l;";
				}
			}
			push @new_dhcp_data,$4;
		} elsif ($b =~ /(^.*)({)(.*)/ and $b !~ /^#/) {
			$s=$1 . $2;
			push @new_dhcp_data,$s;
			foreach my $l (split /;/, $3) {
				$l=trim($l);
				next if ($l =~ /^$/);
				if ($l=~/^#/) {
					# oh crap!, the previous pushed data in the array had a comment!
					# fix it!
					my $last_line=pop @new_dhcp_data;
					push @new_dhcp_data, "$last_line $l";
				} else {
					push @new_dhcp_data,"$l;";
				}
			}
		} elsif ($b =~ /(^.*)(})$/ and $b !~ /^#/) {
			foreach my $l (split /;/, $1) {
				$l=trim($l);
				next if ($l =~ /^$/);
				if ($l=~/^#/) {
					# oh crap!, the previous pushed data in the array had a comment!
					# fix it!
					my $last_line=pop @new_dhcp_data;
					push @new_dhcp_data, "$last_line $l";
				} else {
					push @new_dhcp_data,"$l;";
				}
			}
			push @new_dhcp_data,$2;
		} elsif ($b =~ /;/ and $b !~ /^#/) {
			foreach my $l (split /;/, $b) {
				$l=trim($l);
				next if ($l =~ /^$/);
				if ($l=~/^#/) {
					# oh crap!, the previous pushed data in the array had a comment!
					# fix it!
					my $last_line=pop @new_dhcp_data;
					push @new_dhcp_data, "$last_line $l";
				} else {
					push @new_dhcp_data,"$l;";
				}
			}
		} else {
			push @new_dhcp_data,$b;
		}
	}
	return @new_dhcp_data;
}

sub read_dhcpd4conf {
	my ($start)=@_;
	my $ref;
	my $comments='';
	for (my $a=$start;$a<$#dhcp_data;$a++) {
		my $next_level=0;
		my $next_level_string;
		my $item_comment='';

		chomp $dhcp_data[$a];
		$dhcp_data[$a]=&trim($dhcp_data[$a]);

		next if ($dhcp_data[$a] =~ /^$/);

		if ($dhcp_data[$a] eq '}' ) {
			$comments='';
			return ($ref,$a);
		}

		if ( $dhcp_data[$a] =~ /^#/ ) {
			$comments.=$dhcp_data[$a] . ":::";
			next;
		}

		# option key value options need to stay in order, so they must be in an array
		if ($dhcp_data[$a] =~ /^(option)\s+/) {
			my ($keyword,$key,$value)=split /\s+/, $dhcp_data[$a], 3;
			($value,$item_comment)=split /;/,$value;
			$item_comment=&trim($item_comment);
			my $option_value="$key $value";
			$ref->{item_comment}->{$keyword}->{$option_value}=$item_comment if ($item_comment ne '');
			if ($comments ne '') {
				$ref->{line_comments}->{$keyword}->{$option_value}=$comments;
				$comments='';
			}
			push @{$ref->{$keyword}},"$option_value";
		}

		# hardware ethernet <mac>
		if ($dhcp_data[$a] =~ /^(hardware)\s+/) {
			my ($keyword,$key,$value)=split /\s+/, $dhcp_data[$a], 3;
			($value,$item_comment)=split /;/,$value;
			my $keyword2=$keyword . " " . $key;
			$ref->{$keyword2}[++$#{$ref->{$keyword2}}]=$value;
		}

		# key value for subclass (treat same as option)
		if ($dhcp_data[$a] =~ /^(subclass)(\s+)(.*)(;)/) {
			my ($keyword,$key,$value)=split /\s+/, $dhcp_data[$a], 3;
			($value,$item_comment)=split /;/,$value;
			$ref->{$keyword}{$key}[++$#{$ref->{$keyword}{$key}}]=$value;
		}

		# key value
		if ($dhcp_data[$a] !~ /^(option|hardware|subnet|host|class|subclass|key|if|pool|group|lease|}\s+elsif|}\s+else)\s+/) {
			my ($key,$value)=split /\s+/, $dhcp_data[$a], 2;
			# ($value,$item_comment)=split /\#/,$value;
			# ($value,$dummy)=split /;([^;]+)$/,$value;	# split only on the LAST ';' 
			($value,$item_comment)=split /;/,$value;
			$item_comment=&trim($item_comment);
			$ref->{item_comment}->{$key}->{$value}=$item_comment if ($item_comment ne '');
			$ref->{$key}[++$#{$ref->{$key}}]=$value;
			if ($comments ne '') {
				$ref->{line_comments}->{$key}->{$value}=$comments;
				$comments='';
			}
		}

		# subnet <ip> netmask <ip> {
		# host <hostname> {
		# if ..... {
		# class class_id {
		#### note: take out 'lease here' if we want leases in an array (see below with QQQlease ...
		if ($dhcp_data[$a] =~ /^(subnet|host|lease|class|key|if)\s+/) {
			$next_level=1;
			$line=$dhcp_data[$a];
			($line,$item_comment)=split /{/,$line;
			$line=&trim($line);
			$item_comment=&trim($item_comment);
			my ($keyword,$key)=split /\s+/,$line;
			$next_level_string=$line;
		}

		# subclass class_id eth_id
		if ($dhcp_data[$a] =~ /^(subclass)(\s+)(.*)({)/) {
			$next_level=1;
			$line=$dhcp_data[$a];
			($line,$item_comment)=split /{/,$line;
			$line=&trim($line);
			$item_comment=&trim($item_comment);
			$next_level_string=$line;
		}
		
		# pool {
		# group {
		# Wow, these have no value at all, so we have to treat them as an array.
		# WRONG !!!!!!! THE CAN HAVE A VALUE!!!!, so you should NOT treat them as an ARRAY!
		# we use the named group to mimic macro's in Solaris Legacy DHCP.
		if ($dhcp_data[$a] =~ /^(group|pool)\s+/ ) {
			if ($dhcp_data[$a] =~ /;/) {
				my ($key,$value)=split /\s+/, $dhcp_data[$a], 2;
				($value,$item_comment)=split /;/,$value;
				$item_comment=&trim($item_comment);
				$ref->{item_comment}->{$key}->{$value}=$item_comment if ($item_comment ne '');
				$ref->{$key}[++$#{$ref->{$key}}]=$value;
				if ($comments ne '') {
					$ref->{line_comments}->{$key}->{$value}=$comments;
					$comments='';
				}
			} else {
				$line=$dhcp_data[$a];
				($line,$item_comment)=split /{/, $line;
				$line=&trim($line);
				$item_comment=&trim($item_comment);
	
				$line=ucfirst($line);
				$ref->{$line}[++$#{$ref->{$line}}]='';
				my $cnt=$#{$ref->{$line}};

				$start=++$a;
				my ($ret_hash,$stop)=&read_dhcpd4conf($start);
				$ret_hash->{item_comment}->{this}=$item_comment if ($item_comment ne '');
				if ($comments ne '') {
					$ret_hash->{line_comments}->{this}=$comments;
					$comments='';
				}
				$ref->{$line}[$cnt]=$ret_hash;
				$a=$stop++;
			}
		}

		if ($dhcp_data[$a] =~ /^}\s+els/) {
			$line=$dhcp_data[$a];
			$line=~s/^}//;
			$line=&trim($line); 
			($line,$item_comment)=split /{/, $line;
			$line=&trim($line);

			my ($key,$value)=split /\s+/, $line, 2;
			$key=&trim($key);
			$value=&trim($value);
	
			$start=++$a;
			my ($ret_hash,$stop)=&read_dhcpd4conf($start);

			if ($key eq 'elsif') {
				$key=$key . " " . $value;
			}
			$ref->{$key}=$ret_hash;
			$ret_hash->{item_comment}->{this}=$item_comment if ($item_comment ne '');

			if ($comments ne '') {
				$ret_hash->{line_comments}->{this}=$comments;
				$comments='';
			}
			$a=$stop++;
			$comments='';
			return ($ref,$a);
		}

		### if we need the lease in an array ....
		### probably not, we just take the last one ....
		if ($dhcp_data[$a] =~ /^QQQlease/) {
			$line=$dhcp_data[$a];
			($line,$item_comment)=split /{/, $line;
			$line=&trim($line);

			my ($key,$value)=split /\s+/, $line, 2;
			$key=&trim($key);
			$value=&trim($value);

			my $key=$key . " " . $value;
			$start=++$a;
			my ($ret_hash,$stop)=&read_dhcpd4conf($start);

			push @{$ref->{$key}},$ret_hash;
			$a=$stop++;
		}
	
	
		if ($next_level) {	
			$start=++$a;
			my ($ret_hash,$stop)=&read_dhcpd4conf($start);
			if ($next_level_string =~ /^subnet/) {
				my ($subnet,$subnet_value,$netmask,$netmask_value)=split /\s+/, $next_level_string, 4;
				$ref->{subnet}{$subnet_value}=$ret_hash;
				$ref->{subnet}{$subnet_value}{netmask}[0]=$netmask_value;
				$ref->{subnet}->{$subnet_value}->{item_comment}->{this}=$item_comment if ($item_comment ne '');
				if ($comments ne '') {
					$ref->{subnet}->{$subnet_value}->{line_comments}->{this}=$comments;
					$comments='';
				}
			} elsif ($next_level_string =~ /^host/) {
				my ($host,$host_name)=split /\s+/, $next_level_string, 2;
				$ref->{host}{$host_name}=$ret_hash;
				$ref->{host}->{$host_name}->{item_comment}->{this}=$item_comment if ($item_comment ne '');
				if ($comments ne '') {
					$ref->{host}->{$host_name}->{line_comments}->{this}=$comments;
					$comments='';
				}
			#### note: take out 'lease here' if we want leases in an array (see above with QQQlease ...)
			} elsif ($next_level_string =~ /^lease/) {
				my ($lease,$lease_ip)=split /\s+/, $next_level_string, 2;
				$ref->{lease}{$lease_ip}=$ret_hash;
				$ref->{lease}->{$lease_ip}->{item_comment}->{this}=$item_comment if ($item_comment ne '');
				if ($comments ne '') {
					$ref->{lease}->{$lease_ip}->{line_comments}->{this}=$comments;
					$comments='';
				}
			} elsif ($next_level_string =~ /^key/) {
				my ($k,$k_name)=split /\s+/, $next_level_string, 2;
				$ref->{key}{$k_name}=$ret_hash;
				$ref->{key}->{$k_name}->{item_comment}=$item_comment if ($item_comment ne '');
				if ($comments ne '') {
					$ref->{host}->{$host_name}->{line_comments}->{this}=$comments;
					$comments='';
				}
			} elsif ($next_level_string =~ /^class/) {
				my ($class,$what)=split /\s+/, $next_level_string, 2;
				$ref->{class}{$what}=$ret_hash;
				$ref->{$class}->{$what}->{item_comment}->{this}=$item_comment if ($item_comment ne '');
				if ($comments ne '') {
					$ref->{subclass_hash}->{$what}->{line_comments}->{this}=$comments;
					$comments='';
				}
			} elsif ($next_level_string =~ /^subclass/) {
				my ($subclass,$subclass_id,$value)=split /\s+/, $next_level_string, 3;
				my $subclass_hash="subclass_hash~~~$subclass_id";
				$ref->{$subclass_hash}{value}{$value}=$ret_hash;
				$ref->{$subclass_hash}->{value}->{$value}->{item_comment}->{this}=$item_comment if ($item_comment ne '');
				if ($comments ne '') {
					$ref->{subclass_hash}->{value}->{$value}->{line_comments}->{this}=$comments;
					$comments='';
				}
			} elsif ($next_level_string =~ /^if/) {
				$ref->{$next_level_string}=$ret_hash;
				$ref->{$next_level_string}->{item_comment}->{this}=$item_comment if ($item_comment ne '');
				if ($comments ne '') {
					$ref->{$next_level_string}->{line_comments}->{this}=$comments;
					$comments='';
				}
			} else {
				$ref->{$next_level_string}=$ret_hash;
			}
			$a=$stop++;
		}
	}
	return ($ref,$a);
}

sub arrange_sort {
	my (@keys)=@_;

	# we want "subnet", "group", "if ...", "host" seperate, in this order:
	# if ...., subnet, pool, group, host. 
	# so we save these in another array, not including them in 
	# the new array
	# all the rest will go in the new_array
	# sort the new_array
	# add the exceptions to new_array

	my @new_keys;
	my @special_keys;

	foreach my $i (@keys) {
		if ($i =~ /^(subnet|host|lease|Group\s+.*|Pool\s+.*|subclass_hash.*|class|if\s+.*)$/) {
			$special_keys[++$#special_keys]=$i;
		} else {
			$new_keys[++$#new_keys]=$i;
		}
	}

	@ret_keys=sort @new_keys;

	foreach my $i (@special_keys) {
		if ($i =~ /^(Pool)/) {
			my $n=++$#ret_keys;
			$ret_keys[$n]=$i;
		}
	}
	foreach my $i (@special_keys) {
		if ($i =~ /^(Group)/) {
			my $n=++$#ret_keys;
			$ret_keys[$n]=$i;
		}
	}
	foreach my $i (@special_keys) {
		if ($i =~ /^(if\s+.*)$/) {
			my $n=++$#ret_keys;
			$ret_keys[$n]=$i;
		}
	}
	foreach my $i (@special_keys) {
		if ($i =~ /^(subnet)$/) {
			my $n=++$#ret_keys;
			$ret_keys[$n]=$i;
		}
	}
	foreach my $i (@special_keys) {
		if ($i =~ /^(class)$/) {
			my $n=++$#ret_keys;
			$ret_keys[$n]=$i;
		}
	}
	foreach my $i (@special_keys) {
		if ($i =~ /^(subclass_hash)/) {
			my $n=++$#ret_keys;
			$ret_keys[$n]=$i;
		}
	}
	foreach my $i (@special_keys) {
		if ($i =~ /^(host)$/) {
			my $n=++$#ret_keys;
			$ret_keys[$n]=$i;
		}
	}
	foreach my $i (@special_keys) {
		if ($i =~ /^(lease)$/) {
			my $n=++$#ret_keys;
			$ret_keys[$n]=$i;
		}
	}
	return @ret_keys;
}

# write back the dhcpd.conf file (or dhcpd4.leases file)
sub write_dhcpd4conf {
	############### WRITES TO OPEN FILEDESCRIPTOR "FILE" !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	my ($level,$hash,$parent_key)=@_;
	my ($ref);
	if ($parent_key !~ /^(subnet|host|lease|key|class|value|subclass_hash.*)$/ ) {
		print FILE "\t" x $level;
		print FILE "\n";
	}

	my @arranged_sort_hash_keys=arrange_sort(keys %{$hash});
	# we really need the 'elsif' and 'else' at the nottpm of the list ...
	my $elsif_flag=0;
	my $elsif_value='';
	my $else_flag=0;
	my $else_value='';
	foreach my $k (0 .. $#arranged_sort_hash_keys) {
		if ($arranged_sort_hash_keys[$k] =~ /^elsif/) {
			$elsif_flag++;
			$elsif_value=$arranged_sort_hash_keys[$k];
			delete $arranged_sort_hash_keys[$k];
		}
		if ($arranged_sort_hash_keys[$k] =~ /^else/) {
			$else_flag++;
			$else_value=$arranged_sort_hash_keys[$k];
			delete $arranged_sort_hash_keys[$k];
		}
	}

	my @tmp;
	foreach my $t (@arranged_sort_hash_keys) {
		push @tmp,$t if ($t); 
	}
	push @tmp,$elsif_value if ($elsif_flag);
	push @tmp,$else_value if ($else_flag);
	@arranged_sort_hash_keys= @tmp;

	foreach my $h0 (@arranged_sort_hash_keys) {
		next if ($h0 =~ /item_comment/);
		next if ($h0 =~ /line_comments/);

		if ($h0 =~ /subclass$/) {
			foreach my $h1 (sort keys %{$hash->{subclass}}) {
				foreach my $a (@{$hash->{subclass}->{$h1}}) {
					print FILE "\t" x $level;
					print FILE "$h0 $h1 $a;\n";
				}
			}
			next;
		}

		if (ref($hash->{$h0}) eq "HASH") { 
			if ($parent_key =~ /^(subnet|host|lease|key|class|subclass_hash.*|)$/ )  {
				print FILE "\t" x ($level-1);
				print FILE &process_line_comments($hash->{$h0}->{line_comments}->{this},$level);
				if ($parent_key =~ /subnet/) {
					print FILE "$parent_key $h0 ";
					print FILE "netmask ";
					print FILE "$hash->{$h0}->{netmask}[0]";
					delete $hash->{$h0}->{netmask};
					print FILE " {";
					if ($hash->{$h0}->{item_comment}->{this} ne '') {
						print FILE "\t", $hash->{$h0}->{item_comment}->{this};
					}
				} elsif ($parent_key =~ /subclass_hash/){
					my ($dummy,$v)=split /~~~/, $parent_key;
					print FILE "subclass $v ";
					print FILE keys %{$hash->{$h0}};
					print FILE " {";
					if ($hash->{$h0}->{item_comment}->{this} ne '') {
						print FILE "\t", $hash->{$h0}->{item_comment}->{this};
					}
				} elsif ($parent_key =~ /host/) {
					print FILE "$parent_key $h0";
					print FILE " {";
					if ($hash->{$h0}->{item_comment}->{this} ne '') {
						print FILE "\t", $hash->{$h0}->{item_comment}->{this};
					}
				} elsif ($parent_key =~ /lease/) {
					print FILE "$parent_key $h0";
					print FILE " {";
					if ($hash->{$h0}->{item_comment}->{this} ne '') {
						print FILE "\t", $hash->{$h0}->{item_comment}->{this};
					}
				} elsif ($parent_key =~ /key/) {
					print FILE "$parent_key $h0";
					print FILE " {";
					if ($hash->{$h0}->{item_comment}->{this} ne '') {
						print FILE "\t", $hash->{$h0}->{item_comment}->{this};
					}
				} elsif ($parent_key =~ /class/) {
					print FILE "$parent_key $h0";
					print FILE " {";
					if ($hash->{$h0}->{item_comment}->{this} ne '') {
						print FILE "\t", $hash->{$h0}->{item_comment}->{this};
					}
				}
			} elsif ($h0 =~ /^(if\s+).*$/) {
				print FILE "\t" x $level;
				print FILE &process_line_comments($hash->{$h0}->{line_comments}->{this},$level);
				print FILE "$h0 {";
				if ($hash->{$h0}->{item_comment}->{this} ne '') {
					print FILE "\t", $hash->{$h0}->{item_comment}->{this};
				}
			} elsif ($h0 =~ /^(elsif)/) {
				print FILE &process_line_comments($hash->{$h0}->{line_comments}->{this},$level);
				print FILE "} $h0 { ";
				if ($hash->{$h0}->{item_comment}->{this} ne '') {
					print FILE "\t", $hash->{$h0}->{item_comment}->{this};
				}
				$level-- unless ($parent_key =~ /^elsif/);
			} elsif ($h0 =~ /^(else)/) {
				print FILE &process_line_comments($hash->{$h0}->{line_comments}->{this},$level);
				print FILE "} $h0 {";
				if ($hash->{$h0}->{item_comment}->{this} ne '') {
					print FILE "\t", $hash->{$h0}->{item_comment}->{this};
				}
				$level-- unless ($parent_key =~ /^elsif/);
			}

			$ref=$hash->{$h0};

			if ($parent_key =~ /^(subnet|host|lease|key|class|subclass_hash.*|value|els.*)$/) {
				# not really a next level ;-)
				write_dhcpd4conf($level,$ref,$h);
			} else {
				$level++;
				write_dhcpd4conf($level,$ref,$h0);
				$level--;
			}

			if ($parent_key =~ /^(subnet|host|lease|key|class|subclass_hash.*)$/)  {
				print FILE "\t" x ($level-1);
				print FILE "}\n";
			} elsif ($h0 =~ /^(if\s+).*$/) {
				print FILE "\t" x $level;
				print FILE "}\n";
			}
		} elsif (ref($hash->{$h0}) eq "ARRAY") {
			foreach my $a (0 .. $#{$hash->{$h0}}) {
				print FILE "\t" x $level;
				if ($h0 =~ /^(Group|Pool)/) {
					print FILE &process_line_comments($hash->{$h0}[$a]->{line_comments}->{this},$level);
					print FILE lc($h0), " {";
					if ($hash->{$h0}[$a]->{item_comment}->{this} ne '') {
						print FILE "\t", $hash->{$h0}[$a]->{item_comment}->{this};
					}
					$level++;
					write_dhcpd4conf($level,$hash->{$h0}[$a],$h0);
					$level--;
					print FILE "\t" x $level;
					print FILE "}\n";
				} else {
					print FILE &process_line_comments($hash->{line_comments}->{$h0}->{$hash->{$h0}[$a]},$level+1);
					print FILE "$h0 $hash->{$h0}[$a];";
					my $item_comment=$hash->{item_comment}->{$h0}->{$hash->{$h0}[$a]};
					if ($item_comment ne '' ) {
						print FILE "\t",$item_comment; 
					}
					print FILE "\n";
				}
			}
		} 
	}
}

sub process_line_comments {
	my ($str,$level)=@_;;
	return '' if ($str eq '');
	my $ret_str='';
	foreach my $c (split /:::/,$str) {
		$ret_str.=$c . "\n";
		for($t=0;$t<$level-1;$t++) {
			$ret_str.="\t";
		}
	}
	return $ret_str;
}

sub my_gethostbyname {
	my ($hostname)=@_;
	my ($name,$aliases,$addrtype,$length,@addrs)=gethostbyname($hostname);

	my $ip="";
	foreach $i (@addrs) {
		my ($a,$b,$c,$d)=unpack('C4',$i);
		$ip="$a.$b.$c.$d";
	}
	return $ip;
}

sub delete_from_host {
	my ($keyword,$value)=@_;
	# deletes declaration where the 'hardware ethernet' ($keyword) is a given mac address (value)
	# or the fixed-address ($keyword) is a given ip-address ($value)
	# the 'hardware ethernet' or 'fixed-address' is in the host declaration 'host', which can be in the root, or in a 'Group' of the $dhcp_hash
	foreach my $h (keys %{$dhcp_hash->{host}}) {
		if ($dhcp_hash->{host}->{$h}->{$keyword}[0] eq $value) {
			delete $dhcp_hash->{host}->{$h}; 
		}
	}
}

sub convert_ip2dec {
	# converts an ip address to decimal, so it's easy to subtract and add values.
	my ($d_ip)=@_;
	chomp $d_ip;
	my ($ip_1,$ip_2,$ip_3,$ip_4)=split(/\./,$d_ip);
	my $dec_value=$ip_1*256*256*256 + $ip_2*256*256 + $ip_3*256 + $ip_4;
	return ($dec_value);
}

sub random_tmp_file {
	my $file="/tmp/" .  join("", ('a'..'z','A'..'Z',0..9)[map rand $_, (62)x16]);
	return $file;
}


sub convert_dec2ip {
	# converts an decimal ip address to a dotted notation
	my ($d_ip)=@_;
	chomp $d_ip;
	return (($d_ip >> 24) & 255) . "." . (($d_ip >> 16) & 255) . "." . (($d_ip >> 8) & 255) . "." . ($d_ip & 255);
}

sub check_ip {
	# returns 1 if input is a dotted ip address
	# returns 0 if input is not an ip address
	my ($ip,$quiet)=@_;
	chomp $ip;
	my @octet=split(/\./,$ip,4);
	if (scalar @octet < 4) {
		print "Not a valid ip address, must be 4 octets! \n" if (! $quiet);
		return 0;
	}
	foreach $o (@octet) {
		if ($o > 255 or $o < 0) {
			print "Invalid octet: ($o)! Values cannot be greater than 255!\n" if (! $quiet);
			return 0;
		}
	}
	return 1;
}

sub dec2bin {
	# this is the way you would learn it at school ;-)
	# the same way you would convert a decimal number to ANY base
	my ($dec)=@_;
	my $bin="";     # string with 0's and 1's

	while ($dec) {
		if ($dec % 2) {
			$bin="1" . $bin;
		} else {
			$bin="0" . $bin;
		}
		$dec=int($dec/2); #loop will end if $dec < 1 (like 1/2)
	}
	return $bin;  # as a string
}


sub long_nm2short {
	# check if the long netmask is realy valid. It should have in binary 
	# form, ONLY 1's followed by ONLY 0's
	# a 1 cannot be in between 0's and a 0 cannot be in between 1's 
	# and return the short netmask, return -1 if invalid

	my ($nm)=@_;
        chomp $nm;
	my @octet=split(/\./,$nm,4);
	if (scalar @octet < 3) {
		print "Not a valid netmask, must be 4 octets! \n";
		return -1;
	}

	my $binary_netmask="";
	foreach $o (@octet) {
		if ($o > 255 or $o < 0) {
			print "Invalid octet: ($o)! Values cannot be greater than 255!\n";
			return -1;
		}
		# make sure we have 8 bits length...
		my $tmp_dec2bin=sprintf("%08d",&dec2bin($o)+0);
		$binary_netmask.=$tmp_dec2bin;
		# print $tmp_dec2bin, " ";
	}
	# print "\n";

	@bin_nm_array=split //, $binary_netmask;

	my $bm_short=-1;
	# Counting the 1's will give us the short netmask.
	# Stop counting if we hit a 0 for the presumed value, but we keep on checking 
	# just to see if the netmask is stil valid  
	my $ones=0;
	my $nulls=0;
	foreach $b (@bin_nm_array) {
		$b=$b+0; 
		if ($b and !$nulls) { 
			# this is all correct, we count 1's while we haven't seen 0's
			$ones++;
		}
		if (!$b) {
			$nulls++;
		}
		if ($b and $nulls) {
			print "Not a valid netmask!\n";
			return -1;
		}
	}
	return $ones;
}


sub short_nm2long() {
	my ($short_netmask)=@_;
	chomp $short_netmask;
	if (short_netmask >32) {return -1;}
	$long_netmask=2**32 - (2**(32-$short_netmask));
	return (&convert_dec2ip($long_netmask));
}


sub ip_and_network_info {
	# returns the following information in a hash:
	# ip (the requested ip,dotted)
	# hex_ip (the requested ip address in hex)
	# netmask (dotted)
	# bitmask (short netmask)
	# network (dotted)
	# broadcast (dotted)
	# host_ip_start	(first available ip that can be assigned to a host)
	# host_ip_end	(last available ip that can be assigned to a host)
	# host_range (network+1   .... broadcast-1, in other words the usable ip addresses for hosts) 
	# nr_ips (numbers of ip addresses in the network)

	# error : 1 is error
	my ($ip,$nm)=@_;

	my $ret;
	$ret->{error}=0;

	if ($ip !~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/ ) {
		# oh, ip is decimal, not dotted!
		$ip=&convert_dec2ip($ip);
	}

	if ($nm>=0 and $nm <=32) {
		$nm=&short_nm2long($nm);
	}

	$ret->{error}=1 if (! &check_ip($ip)); 
	$ret->{error}=1 if (! &check_ip($nm));

	my $ip_dec=&convert_ip2dec($ip);
	my $nm_dec=&convert_ip2dec($nm);

	my $network_dec=$ip_dec & $nm_dec; 
	my $network_dotted=&convert_dec2ip($network_dec);

	$ret->{ip}=$ip;
	$ret->{hex_ip}=sprintf("%08x",$ip_dec);
	$ret->{dec_ip}=$ip_dec;
	$ret->{netmask}=$nm;
	$ret->{bitmask}=&long_nm2short($nm);
	$ret->{error}=1 if ($ret->{bitmask} == -1);
	$ret->{network}=$network_dotted;
	$ret->{dec_network}=$network_dec;
	$ret->{nr_ips}=2**(32-$ret->{bitmask});        # number of ip addresses in this network
	$ret->{broadcast}=&convert_dec2ip($network_dec + $ret->{nr_ips} - 1);
	$ret->{ip_start}=$network_dotted;
	$ret->{ip_end}=&convert_dec2ip($network_dec + $ret->{nr_ips});
	$ret->{host_ip_start}=&convert_dec2ip($network_dec + 1);
	$ret->{host_ip_end}=&convert_dec2ip($network_dec + $ret->{nr_ips} - 2);
	$ret->{host_range}=$ret->{host_ip_start} . " - " . $ret->{host_ip_end};

	return($ret);
}
sub mytimestamp {
        my ($sec,$min,$hour,$mday,$mon, $year,$wday,$yday,$isdst)=localtime(time);
	if ($t) {
		($sec,$min,$hour,$mday,$mon, $year,$wday,$yday,$isdst)=localtime($t);
	}
        $mon=$mon+1;
        $year=$year+1900;
        my $date=sprintf("%04d%02d%02d%02d%02d%02d", $year,$mon,$mday,$hour,$min,$sec);
        return $date;
}

sub date_and_time_stamp {
	my ($t)=@_;
        my ($sec,$min,$hour,$mday,$mon, $year,$wday,$yday,$isdst)=localtime(time);
	if ($t) {
		($sec,$min,$hour,$mday,$mon, $year,$wday,$yday,$isdst)=localtime($t);
	}
        $mon=$mon+1;
        $year=$year+1900;
        my $date=sprintf("%04d-%02d-%02d %02d:%02d", $year,$mon,$mday,$hour,$min);
        return $date;
}

sub convert_mac2MAC {
	# takes input mac address as 00:09:3D:13:45:5D
	# and outputs: 00093D13455D
	my ($mac)=@_;
	my @mac_array=split(/:/,$mac);
	my $dhcpmac="";
	foreach my $i (@mac_array) {
		$dhcpmac="$dhcpmac" . sprintf("%02s",$i);
	}
	return (uc($dhcpmac));
}

sub convert_MAC2mac {
	# takes input mac address as 00093D13455D
	# and outputs: 00:09:3D:13:45:5D
	my ($m)=@_;
	my $m1=substr($m,0,2);
	my $m2=substr($m,2,2);
	my $m3=substr($m,4,2);
	my $m4=substr($m,6,2);
	my $m5=substr($m,8,2);
	my $m6=substr($m,10,2);
	$ret_mac="$m1:$m2:$m3:$m4:$m5:$m6";
	return ($ret_mac);
}

sub convert_mac2generic {
	# converts 00093D13455D to 00:09:3D:13:45:5D
	# and 0:9:3d:13:45:5d to 00:09:3D:13:45:5D
	my ($m)=@_;
	if ($m eq "") {
		return $m;
	}
	if ($m !~ /:/) {
		$m=&convert_MAC2mac($m);
	} else {
		my @mac_array=split(/:/,$m);
		my $gen_mac="";
		my $cnt=0;
		foreach my $i (@mac_array) {
			if ($#mac_array==$cnt) {
				$gen_mac.=sprintf("%02s",$i);
			} else {
				$gen_mac.=sprintf("%02s:",$i);
			}
			$cnt++;
		}
		$m=$gen_mac;
	} 
	$m=lc($m);
	return $m;
}

sub check_mac {
	# checks the mac address for errors:
	# valid addresses are:
	# 0:9:3d:13:45:5d
	# 00:09:3D:13:45:5D
	# 00093D13455D
	# use convert_mac2generic to get all these in 00:09:3d:13:45:5d
	# format (all lowercase) 
	my ($mac_address)=@_;
	if ($mac_address !~ /:/) {
		if (length($mac_address) != 12) { 
			return (0);
		}
		$mac_address=convert_MAC2mac($mac_address);
	}
	$mac_address.=" ";
	my $mac_pattern="";
	for (my $i=0;$i<6;$i++) {
		$mac_pattern.="[0-9a-fA-F]+";
		$mac_pattern.=":" if ($i != 5);
	}
	if ($mac_address =~ /$mac_pattern\s+/) {
		return (1);
	} else {
		return (0);
	} 
}


sub check_network {
	my ($nw,$nm)=@_;        # both entries MUST BE DECIMAL!!
	# Lets check if network and netmask match ....
        my $network_info=&ip_and_network_info($nw,$nm);
}

sub omshell_status {
	my ($nw)=@_;

	if (! -x $omshell) {
		print STDERR "ERROR: Cannot execute \"$omshell\"\n"; 
		return;
	}

	# where are all the leases ???
	my @addresses;
	foreach my $ips (@{$dhcp_hash->{subnet}->{$nw}->{range}}) {
		my ($ipstart,$ipend)=split /\s+/,$ips;
		my $comment='';
		if ($dhcp_hash->{subnet}->{$nw}->{item_comment}->{range}->{$ips} ne '') {
			$comment=$dhcp_hash->{subnet}->{$nw}->{item_comment}->{range}->{$ips};
			$comment=~s/^#//;
			$comment=&trim($comment);
		}
		if ($ipend ne '') {
			my $s=&convert_ip2dec($ipstart);
			my $e=&convert_ip2dec($ipend);
			for(my $i=$s;$i<=$e;$i++) {
				push @addresses,[$nw,&convert_dec2ip($i),$comment];
			}
		} else {
			push @addresses,[$nw,$ipstart,$comment];
		}
	}

	my $lease_hash;
	foreach my $a (@addresses) {
		my ($network_ip,$address,$comment)=@$a;
		my $omshell_out=&random_tmp_file;
		open (OMSHELL, "|$omshell > $omshell_out 2>&1") || die ("Unable to open omshell\n");
		print OMSHELL "port ",  $dhcp_hash->{'omapi-port'}->[0], "\n";
		print OMSHELL "key omapi_key ", $dhcp_hash->{key}->{omapi_key}->{secret}[0], "\n";
		print OMSHELL "connect\n";
		print OMSHELL "new lease\n";
		print OMSHELL "set ip-address = $address\n";
		print OMSHELL "set state 9 lookup\n";
		print OMSHELL "open\n";
		close OMSHELL;

		open(OUT,$omshell_out);
		@data=<OUT>;
		close OUT;
		unlink OUT;

		my $ipdec=&convert_ip2dec($address);

		foreach my $l (@data) {
			chomp $l;
			next if ($l =~ /^>/);
			my ($key,$value)=split /=/,$l;
			$key=&trim($key);
			$value=&trim($value);
			$lease_hash->{$network_ip}->{$ipdec}->{$key}=$value;
		}
		$lease_hash->{$network_ip}->{$ipdec}->{comment}=$comment;
		
	}

	#print STDERR Dumper ($lease_hash),"\n";

	@ret_array=();
	# format of @ret_array:
	# clientip, mac-address, flags, lease_expiration, comment
	#
	# clientip is in DECIMAL format
	# mac address: aa:bb:cc:dd:ee:ff
	# lease expiration in seconds since Jan 01, 1970

	foreach my $ip (sort keys %{$lease_hash->{$nw}}) {
		my $clientip=$ip;
		my $mac=$lease_hash->{$nw}->{$ip}->{'hardware-address'};
		my $flags=$lease_hash->{$nw}->{$ip}->{flags};
		my $lease_expiration=0;
		my $macro='';
		if ($lease_hash->{$nw}->{$ip}->{ends}) {
			my $lease_expiration_hex=$lease_hash->{$nw}->{$ip}->{ends};
			$lease_expiration_hex=~s/://g;
			$lease_expiration=hex($lease_expiration_hex) + 0;
		}
		$comment=$lease_hash->{$nw}->{$ip}->{comment};
		push @ret_array,[$ip,$mac,$flags,$lease_expiration,$macro,$comment];
	}
	return @ret_array;
}

sub dhcpd4_status {
	# subroutine name derived from 'omshell_status' ...
	# kind of takes all the hosts entries from the dhcpd4.conf and grab the leasetime and other stuff.
	my ($nw)=@_;

	my @addresses=();
	# grab the subnet for this network ...
	my $subnet=$dhcp_hash->{subnet}->{$nw}->{netmask}[0];

	my $network_info=&ip_and_network_info($nw,$subnet);
	my $nw_start=$network_info->{dec_ip};
	my $nw_end=$nw_start + $network_info->{nr_ips};

	@ret_array=();
	# format of @ret_array:
	# clientip, mac-address, flags, lease_expiration, comment
	#
	# clientip is in DECIMAL format
	# mac address: aa:bb:cc:dd:ee:ff
	# lease expiration in seconds since Jan 01, 1970

	foreach my $h (keys %{$dhcp_hash->{host}}) {
		my $clientip=convert_ip2dec($dhcp_hash->{host}->{$h}->{'fixed-address'}[0]);
		next if ($clientip <= $nw_start or $clientip >= $nw_end);
		my $mac=$dhcp_hash->{host}->{$h}->{'hardware ethernet'}[0];
		my $flags="03"; 		# manual+permanent
		my $lease_expiration=-1;
		my $macro='';
		$macro=$dhcp_hash->{host}->{$h}->{group}[0];
		my $comment=$dhcp_hash->{host}->{$h}->{item_comment}->{this};
		$comment=~s/^#\s+//;
		push @ret_array,[$clientip,$mac,$flags,$lease_expiration,$macro,$comment];
	}
	return @ret_array;
}

sub delete_dynamic_ip {
	# delete dynamic ip address from the range, in this subnet, and also delete the ip address from the 
	# $dhcpd4_leases_file

	my ($nw,$client_ip)=@_;

	my $dhcpd4_leases_hash=&read_leases_file;
	my $lease_file_touched=0;

	# check the 'range' for dynamic addresses in the network ...
	my @dynamic_ips=();
	foreach my $r (@{$dhcp_hash->{subnet}->{$nw}->{range}}) {
		my ($start,$end)=split /\s+/, $r;
		my $start_dec=&convert_ip2dec($start);
		if ($end ne "") {
			my $end_dec=&convert_ip2dec($end);
			for (my $k=$start_dec;$k<=$end_dec;$k++) {
				push @dynamic_ips,$k;
			}
		} else {
			push @dynamic_ips,$start_dec;
		}
	}

	my @array_counter=();
	foreach my $d (0 .. $#dynamic_ips) {
		if ($dynamic_ips[$d] ==  $client_ip_dec) {
			push @array_counter, $d; 
		}
	}
	foreach my $d (@array_counter) {
		splice (@dynamic_ips,$d,1);
	}

	@dynamic_ips=sort {$a <=> $b} @dynamic_ips;

	# rewrite the ranges ...
	delete $dhcp_hash->{subnet}->{$nw}->{range};

	my @range_group=();
	push @dynamic_ips,0;		# make the last entry ZERO 
	foreach my $array_counter (0 .. $#dynamic_ips) {
		push @range_group, &convert_dec2ip($dynamic_ips[$array_counter]);
		if ($dynamic_ips[$array_counter+1] != $dynamic_ips[$array_counter] + 1) {
			# seems that the next entry is NOT 1 higher, so write the range ...
			my $range='';
			last if ($range_group[0] eq "0.0.0.0");
			if ($#range_group > 0 ) {
				$range=$range_group[0] . " " . $range_group[$#range_group];
			} else {
				$range=$range_group[0];
			}
			push @{$dhcp_hash->{subnet}->{$nw}->{range}},$range;
			@range_group=();
		}
	}
	# check the leases file, delete entry with ip address
	foreach my $ip (keys %{$dhcpd4_leases_hash->{lease}}) {
		if ($ip eq $client_ip) {
			delete $dhcpd4_leases_hash->{lease}->{$ip};
			$lease_file_touched++;
		}
	}
        if ($lease_file_touched) {
                # rewrite the $dhcpd4_lease_file, since the hash has changed ...
                if ($debug) {
                        open(FILE,">&STDOUT") or die "Can't dup STDOUT: $!";
                        write_dhcpd4conf(0,$dhcpd4_leases_hash,"");
                        close FILE;
                } else {
                        open(FILE,">$dhcpd4_leases_file") or die "Cannot open \"$dhcpd4_leases_file\" for write: $!\n";
                        write_dhcpd4conf(0,$dhcpd4_leases_hash,"");
                        close FILE;
                }
        }
}

sub pntadm_P {
	my ($nw)=@_;
	@pntadm_P_array=(&omshell_status($nw),&dhcpd4_status($nw));
	@pntadm_P_array=sort {$a->[0] <=> $b->[0]} @pntadm_P_array;

	my $l_clientid=14;
	my $l_flags=5;
	my $l_clientip=15;
	my $l_serverip=15;
	my $l_f_lease_expiration=16;
	my $l_macro=3;
	my $l_comment=0;

	my @clean_array=();
	foreach my $i (@pntadm_P_array) {
		my ($ip,$mac,$flags,$lease_expiration,$macro,$comment)=@$i;
		my $clientid="01" . convert_mac2MAC($mac);
		my $clientip=&convert_dec2ip($ip);
		$clientid="00" if ($mac eq '');
		$flags="00" if ($flags eq '');
		my $serverip=`hostname`; chomp $serverip;
		if ($option{x}) {
			$f_lease_expiration=$lease_expiration;
		} elsif ($option{v}) {
			if ($lease_expiration < 0 ) {
				$f_lease_expiration="Forever";
			} elsif ($lease_expiration == 0 ) {
				$f_lease_expiration="Zero";
			} else {
				$f_lease_expiration=&date_and_time_stamp($lease_expiration);
			}
		} else {
			if ($lease_expiration < 0 ) {
				$f_lease_expiration="Forever";
			} elsif ($lease_expiration == 0 ) {
				$f_lease_expiration="Zero";
			} else {
				$f_lease_expiration=&date_and_time_stamp($lease_expiration);
			}
		}
		$macro='N/A' if ($macro eq '');
		$l_clientid=length($clientid) if (length($clientid) > $l_clientid);
		$l_flags=length($flags) if (length($flags) > $l_flags);
		$l_clientip=length($clientip) if (length($clientip) > $l_clientip);
		$l_serverip=length($serverip) if (length($serverip) > $l_serverip);
		$l_f_lease_expiration=length($f_lease_expiration) if (length($f_lease_expiration) > $l_f_lease_expiration);
		$l_macro=length($macro) if (length($macro) > $l_macro);
		$l_comment=length($comment) if (length($comment) > $l_comment);
		push @clean_array, [$clientid,$flags,$clientip,$serverip,$f_lease_expiration,$macro,$comment];
	}

	printf ("%-${l_clientid}s  %-${l_flags}s  %-${l_clientip}s  %-${l_serverip}s  %-${l_f_lease_expiration}s  %-${l_macro}s  %s\n\n", 
		"Client ID", "Flags", "Client IP", "Server IP", "Lease Expiration", "Macro", "Comment");
	foreach my $i (@clean_array) {
		my ($clientid,$flags,$clientip,$serverip,$f_lease_expiration,$macro,$comment)=@$i;
		printf ("%-${l_clientid}s  %-${l_flags}s  %-${l_clientip}s  %-${l_serverip}s  %-${l_f_lease_expiration}s  %-${l_macro}s  %s\n",
			$clientid,$flags,$clientip,$serverip,$f_lease_expiration,$macro,$comment);
	}
}

sub pntadm_L {
	# show all configured networks..., but we want them sorted ;-)
	my @nw_array=();
	foreach my $i (keys %{$dhcp_hash->{subnet}}) {
		my $nm_dotted=$dhcp_hash->{subnet}->{$i}->{netmask}[0];
		push @nw_array,[&convert_ip2dec($i),$i,&long_nm2short($nm_dotted),$nm_dotted];
	}

	foreach my $i (sort {$a->[0] <=> $b0->[0]} @nw_array) {
		my ($nw_dec,$nw_dotted,$bitmask,$nw_netmask_dotted)=@$i;
		if ($option{v}) {
			print $nw_dotted, "/", $bitmask, "\n";
		} else {
			print $nw_dotted, "\n";
		}
	}
	exit;
}

sub pntadm_C {
	my ($nw,$nm)=@_;	# network and bitmask, BOTH decimal

	# Lets check if network and netmask match ....
	my $network_info=&ip_and_network_info($nw,$nm);
	if ($network_info->{dec_network} != $nw) {
		print STDERR "ERROR\n";
		print STDERR " Network ip address: ", &convert_dec2ip($nw) ,
			" does not match with network mask $network_info->{netmask} (/",
			$network_info->{bitmask}, ")!!\n";
		print STDERR " The network should be: ", $network_info->{network}, "\n";
		print STDERR "\n";
		print STDERR " ip:                            $network_info->{ip}\n";
		print STDERR " network:                       $network_info->{network}\n";
		print STDERR " netmask:                       $network_info->{netmask}\n";
		print STDERR " bitmask:                       $network_info->{bitmask}\n";
		print STDERR " broadcast:                     $network_info->{broadcast}\n";
		print STDERR " Host Range:                    $network_info->{host_range}\n";
		exit 1;
	}

	# lets' see if this network with bitmap is available ...
	my $nw_start=$nw;
	my $nw_end=$nw_start + 2**(32-$nm) - 1;

	foreach my $e (keys %{$dhcp_hash->{subnet}}) {
		my $e_nw=&convert_ip2dec($e);
		my $e_nm=&long_nm2short($dhcp_hash->{subnet}->{$e}->{netmask}[0]);
		my $e_nw_start=$e_nw;
		my $e_nw_end=$e_nw_start + 2**(32-$e_nm) - 1;

#		print STDERR "> $nw_start - $nw_end <              > $e_nw_start - $e_nw_end <\n";
#		print STDERR &convert_dec2ip($nw_start), " - ", &convert_dec2ip($nw_end), "       ", &convert_dec2ip($e_nw_start), " - ", &convert_dec2ip($e_nw_end),"\n"; 


		if ($e_nw_start == $nw_start and $e_nw_end == $nw_end) {
			print STDERR "ERROR: Entry ", $network_info->{network}, "/", $network_info->{bitmask}, " already exists\n";
			exit 1;
		}
		if ($e_nw_start >= $nw_start and $e_nw_start <= $nw_end and $e_nw_end >= $nw_end) {
			print STDERR "ERROR: Entry ", $network_info->{network}, "/", $network_info->{bitmask}, " overlaps network $e/$e_nm\n";
			exit 1;
		}
		if ($e_nw_start <= $nw_start and $e_nw_end >= $nw_end) {
			print STDERR "ERROR: Entry ", $network_info->{network}, "/", $network_info->{bitmask}, " overlaps network $e/$e_nm\n";
			exit 1;
		}
		if ($e_nw_start >= $nw_start and $e_nw_end <= $nw_end) {
			print STDERR "ERROR: Entry ", $network_info->{network}, "/", $network_info->{bitmask}, " overlaps network $e/$e_nm\n";
			exit 1;
		}
		if ($e_nw_start <= $nw_start and $e_nw_end >= $nw_start and $e_nw_end <= $nw_end) {
			print STDERR "ERROR: Entry ", $network_info->{network}, "/", $network_info->{bitmask}, " overlaps network $e/$e_nm\n";
			exit 1;
		}
	}

	my $new_network=&convert_dec2ip($nw);
	my $new_netmask=&short_nm2long($nm);

	push @{$dhcp_hash->{subnet}->{$new_network}->{netmask}},$new_netmask;
}

sub pntadm_R {
	my ($nw)=@_;	
	my $nw_dec=&convert_ip2dec($nw);
	my ($nm_short)=&long_nm2short($dhcp_hash->{subnet}->{$nw}->{netmask}[0]);

	# delete the network and all sub entries !!!
	print "Deleting network $nw! \n";
	delete $dhcp_hash->{subnet}->{$nw}; 

	# delete all hosts that are in this network .....
	my $nw_start=$nw_dec;
	my $nw_end=$nw_start + 2**(32-$nm) - 1;

	for my $h (keys %{$dhcp_hash->{host}}) {
		my $ip_dec=convert_ip2dec($dhcp_hash->{host}->{$h}->{'fixed-address'}[0]);
		if ($ip_dec >= $nw_start and $ip_dec <= $nw_end) {
			# fit's in network, so delete entry!
			my $Group="Group " . $dhcp_hash->{host}->{$h}->{group}[0];
			delete $dhcp_hash->{$Group};	# delete the group macro as well (if used)
			delete $dhcp_hash->{host}->{$h};
		}
	}
}

sub read_leases_file {
	# reads the leases file, returns the hash ...
	# use &read_dhcpd4conf routine to read the leases file, however, it takes data from @dhcpd_data, so we need to 
	# fill that first
	open(DHCPD4LEASES,"$dhcpd4_leases_file");
	@dhcp_data=<DHCPD4LEASES>;
	close DHCPD4LEASES;
	push @dhcp_data, "\n";

	my ($ret_hash,$dummy)=&read_dhcpd4conf(0);
	return $ret_hash;
}

sub pntadm_D {
	my ($nw)=@_;	
	my ($client_ip)='';

	if ($option{z}) {
		# delete entry with mac address as parameter
		my $mac='';
		if (&check_mac($option{D})) {
			$mac=&convert_mac2generic($option{D});
			&delete_from_host('hardware ethernet',$mac);
		} else {
			# see if the entry has 14 characters, with leading 01 ..
			if (length($option{D}) == 14) {
				$mac=substr($option{D},2,12);
				$mac=&convert_mac2generic($mac);
				if (&check_mac($mac)) {
					&delete_from_host('hardware ethernet',$mac);
				} else {
					print "Cannot recognize \"$option{D}\" as a mac address\n";
					exit;
				}
			} else {
				print "Cannot recognize \"$option{D}\" as a mac address\n";
				exit;
			}
		}

		my $dhcpd4_leases_hash=&read_leases_file;
		my $lease_file_touched=0;
		# check the leases file, delete entry with mac address $mac
		foreach my $ip (keys %{$dhcpd4_leases_hash->{lease}}) {
			if ($dhcpd4_leases_hash->{lease}->{$ip}->{'hardware ethernet'}[0] eq $mac) {
				delete $dhcpd4_leases_hash->{lease}->{$ip};
				$lease_file_touched++;
			}
		}
		if ($lease_file_touched) {
			# rewrite the $dhcpd4_lease_file, since the hash has changed ...
			if ($debug) {
				open(FILE,">&STDOUT") or die "Can't dup STDOUT: $!";
				write_dhcpd4conf(0,$dhcpd4_leases_hash,"");
				close FILE;
			} else {
				open(FILE,">$dhcpd4_leases_file") or die "Cannot open \"$dhcpd4_leases_file\" for write: $!\n";
				write_dhcpd4conf(0,$dhcpd4_leases_hash,"");
				close FILE;
			}
		}
	} else {
		if (&check_ip($option{D},1)) {
			# oh, it's an ip-address;
			$client_ip=$option{D};
		} else {
			# a name!, let's look up it's ip-address ...
			$client_ip=my_gethostbyname($option{D});
		}
		if (! length($client_ip)) {
			print "Unknown hostname \"$option{D}\"\n";
			exit 1;
		} 
		# let's check if this ip address is actually in the network;-)
		my $bitmask=&long_nm2short($dhcp_hash->{subnet}->{$nw}->{netmask}[0]);
		if (! $bitmask) {
			print "No such network \"$nw\".\n";
			exit;
		}
		
		$client_ip_dec=&convert_ip2dec($client_ip);
		my $nw_start=&convert_ip2dec($nw);
		my $nw_end=$nw_start + 2**(32-$bitmask) - 1;

		if ($client_ip_dec >= $nw_start and $client_ip_dec  <= $nw_end) {
			&delete_from_host('fixed-address',$client_ip);
		} else {
			print "IP address \"$client_ip\" not in network \"$nw/$bitmask\"\n";
			exit 1;
		}

		# delete the IP address from the range in this network, if it's there, and also rewrite the leases file if needed
		&delete_dynamic_ip($nw,$client_ip);
	}
		
}

sub pntadm_A {
	my ($nw)=@_;	
	# add client options ....

	# check of name or ip address already exist, if so, then exit with errno=1 
	# name or ip ?
	my $client_ip='';
	my $client_name='';
	if (&check_ip($option{A},1)) {
		# oh, it's an ip-address;
		$client_ip=$option{A};
		my ($x_name,$x_aliases,$x_addrtype,$x_length,@x_addrs)=gethostbyaddr(inet_aton($client_ip),AF_INET);
		$client_name=$x_name;
	} else {
		# a name!, let's look up it's ip-address ...
		$client_ip=my_gethostbyname($option{A});
		$client_name=$option{A};
	}
	if (! length($client_ip)) {
		print "Unknown hostname \"$option{A}\"\n";
		exit 1;
	}
	my $client_ip_dec=&convert_ip2dec($client_ip);

	# now check if this ip address is in the network range given ...
	my $nw_start=&convert_ip2dec($network);
	my $bitmask=&long_nm2short($dhcp_hash->{subnet}->{$nw}->{netmask}[0]);
	if (! $bitmask) {
		print "No such network \"$network\".\n";
		exit;
	}

	my $nw_end=$nw_start + 2**(32-$bitmask) - 1;
	if ($client_ip_dec < $nw_start or $client_ip_dec > $nw_end) {
		print "IP address \"$client_ip\" not in network \"$network/$bitmask\"\n";
		exit 1;
	}


	# check the 'range' for dynamic addresses in the network ...
	my @dynamic_ips=();
	foreach my $r (@{$dhcp_hash->{subnet}->{$nw}->{range}}) {
		my ($start,$end)=split /\s+/, $r;
		my $start_dec=&convert_ip2dec($start);
		if ($end ne "") {
			my $end_dec=&convert_ip2dec($end);
			for (my $k=$start_dec;$k<=$end_dec;$k++) {
				push @dynamic_ips,$k;
			}
		} else {
			push @dynamic_ips,$start_dec;
		}
	}

	foreach my $d (@dynamic_ips) {
		if ($d ==  $client_ip_dec) {
			print STDERR "$0: $client_ip already exists.\n";
			exit 1;
		}
	}
	
	# check the hosts declarations ...
	foreach my $h (keys %{$dhcp_hash->{host}}) {
		if ($dhcp_hash->{host}->{$h}->{'fixed-address'}[0] eq $client_ip) {
			print STDERR "$0: $client_ip already exists.\n";
			exit 1;
		}
	}

	if ($option{h}) {;}	# client hostname, it should actually add the hostname to the NIS/NIS+ or /etc/hosts table. IGNORE THIS
	if ($option{s}) {;}	# don't know what to do with -s, it's always the DHCP server itself for ISC DHCP

	my $comment='';
	if ($option{c} ne '') { 
		$comment=$option{c};
	}

	if ($option{e}) {
		# I don't know what to do with this option if this is a permanent entry ....
	}

	my $client_id=$option{i};
	my $harware_ethernet='';
	my $dhcp_client_identifier='';
	# what client id's can we have ?
	# 00 (Dynamic), 01AABBCCDDEEFF (01<MAC>), 00FF200008FFFFFFFFFFFFAABBCCDDEEFF, (group id + Mac) 

	if ($client_id ne '') {
		if ($option{I}) {
			$harware_ethernet=&convert_mac2generic($client_id);
			if (! &check_mac($client_id)) {
				print STDERR "$0: \"$client_id\" is not a valid mac address.\n";
				exit 1;
			}
		} else {
			my $l=length($client_id);
			if ($l%2) {
				print STDERR "$0: \"$client_id\" is not a valid client ID (needs even # of characters). (Or did you miss the -I option?)\n";
				exit 1;
			} elsif ($l > 14) { 
				# hey, probably an entry with a dhcp-client-identifier!
				# take the last 12 characters for the Mac address, and the rest for the dhcp-client-identifier
				# $dhcp_client_identifier=substr($client_id,0,$l-12);
				$dhcp_client_identifier=$client_id;
				$dhcp_client_identifier=~s/(.{2})/:\1/g;
				$dhcp_client_identifier=~s/^://;
				$harware_ethernet=&convert_mac2generic(substr($client_id,$l-12,12));
			} elsif ($l == 14) {
				$harware_ethernet=&convert_mac2generic(substr($client_id,$l-12,12));
			} elsif ($l == 12) {
				$harware_ethernet=&convert_mac2generic($client_id);
			} elsif ($client_id eq "00") {
				$dynamic_flag++;
			} else  {
				print STDERR "$0: \"$client_id\" is not a valid client id.\n";
				exit 1;
			} 
		}
		$harware_ethernet=lc($harware_ethernet);
		$dhcp_client_identifier=lc($dhcp_client_identifier);

		# check the hosts declarations if that hardware address is already there, delete it !
		foreach my $h (keys %{$dhcp_hash->{host}}) {
			if (lc($dhcp_hash->{host}->{$h}->{'hardware ethernet'}[0]) eq $harware_ethernet) {
				delete $dhcp_hash->{host}->{$h};
			}
		}
	}
	if ($option{u} ne '') {
		$dhcp_client_identifier=$option{u};
	}

	my $flags=uc($option{f});

	if ($flags =~ /[A-Z]+/) { 
		@flag_array=split /\+/, $flags;
		$flags=0;
		foreach my $f (@flag_array) {
			if ($f eq "DYNAMIC") {
				$flags+=0;
			} elsif ($f eq "PERMANENT") {
				$flags+=1;
			} elsif ($f eq "MANUAL") {
				$flags+=2;
			} elsif ($f eq "UNUSABLE") {
				$flags+=4;
			} elsif ($f eq "BOOTP") {
				$flags+=8;
			}
		}
	} 
	$flags+=0;

	$dynamic_flag++ if (! $flags );

	my $macro=$option{m};
	my $implied_macro=0;
	my $ippattern='^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$';

	if ($macro =~ /$ippattern/) {
		$implied_macro++;
	}

	my $Groupname="Group " . $macro;

	if ($macro ne '') {
		if ($implied_macro) {
			if (ref($dhcp_hash->{subnet}->{$nw}) ne "HASH") {
				print STDERR "$0: network $nw is not defined, implied macro will not work\n"; 
				exit 1;
			}
		} elsif (ref($dhcp_hash->{$Groupname}) ne "ARRAY") {
			print STDERR "$0: macro \"$macro\": does not exists.\n"; 
			exit 1;
		}
	}


	if ($harware_ethernet ne '' and ! $dynamic_flag) {
		# well, at least it's a host entry ....
		delete $dhcp_hash->{host}->{$client_name};
		push @{$dhcp_hash->{host}->{$client_name}->{'fixed-address'}}, $client_ip;
		push @{$dhcp_hash->{host}->{$client_name}->{'hardware ethernet'}}, $harware_ethernet;
		if ($dhcp_client_identifier ne '') {
			push @{$dhcp_hash->{host}->{$client_name}->{'dhcp-client-identifier'}}, $dhcp_client_identifier;
		}
		if ($comment ne '') {
			$dhcp_hash->{host}->{$client_name}->{'item_comment'}->{this}="# " . $comment;
		}
		if ($macro ne '' and !$implied_macro) {
			push @{$dhcp_hash->{host}->{$client_name}->{'group'}}, $macro;
		}
	}

	if ($dynamic_flag) {
		# add the entry in a range ...
		# use the array with dynamic ip addresses which was already created , BUT THEY ARE IN DECIMAL!!!
		push @dynamic_ips, $client_ip_dec;

		@dynamic_ips=sort {$a <=> $b} @dynamic_ips;

		# rewrite the ranges ...
		delete $dhcp_hash->{subnet}->{$nw}->{range};

		my @range_group=();
		push @dynamic_ips,0;		# make the last entry ZERO 
		foreach my $array_counter (0 .. $#dynamic_ips) {
			push @range_group, &convert_dec2ip($dynamic_ips[$array_counter]);
			if ($dynamic_ips[$array_counter+1] != $dynamic_ips[$array_counter] + 1) {
				# seems that the next entry is NOT 1 higher, so write the range ...
				my $range='';
				last if ($range_group[0] eq "0.0.0.0");
				if ($#range_group > 0 ) {
					$range=$range_group[0] . " " . $range_group[$#range_group];
				} else {
					$range=$range_group[0];
				}
				push @{$dhcp_hash->{subnet}->{$nw}->{range}},$range;
				@range_group=();
			}
		}
		if ($comment ne '') {
		  	$dhcp_hash->{subnet}->{$nw}->{item_comment}->{range}->{$client_ip}="# " . $comment;
		}
	}
}

sub pntadm_M {
	my ($nw)=@_;	
	# modify client options ....

	# check of name or ip address already exist, if not, then exit with errno=1 (we change an EXISTING entry) 
	# name or ip ?
	my $client_ip='';
	my $client_name='';
	if (&check_ip($option{M},1)) {
		# oh, it's an ip-address;
		$client_ip=$option{M};
		my ($x_name,$x_aliases,$x_addrtype,$x_length,@x_addrs)=gethostbyaddr(inet_aton($client_ip),AF_INET);
		$client_name=$x_name;
	} else {
		# a name!, let's look up it's ip-address ...
		$client_ip=my_gethostbyname($option{M});
		$client_name=$option{M};
	}
	if (! length($client_ip)) {
		print "Unknown hostname \"$option{M}\"\n";
		exit 1;
	}
	my $client_ip_dec=&convert_ip2dec($client_ip);

	# now check if this ip address is in the network range given ...
	my $nw_start=&convert_ip2dec($network);
	my $bitmask=&long_nm2short($dhcp_hash->{subnet}->{$nw}->{netmask}[0]);
	if (! $bitmask) {
		print "No such network \"$network\".\n";
		exit;
	}

	my $nw_end=$nw_start + 2**(32-$bitmask) - 1;
	if ($client_ip_dec < $nw_start or $client_ip_dec > $nw_end) {
		print "IP address \"$client_ip\" not in network \"$network/$bitmask\"\n";
		exit 1;
	}

	my $found_client=0;

	# check the hosts declarations ...
	my $found_client_host=0;
	foreach my $h (keys %{$dhcp_hash->{host}}) {
		if ($dhcp_hash->{host}->{$h}->{'fixed-address'}[0] eq $client_ip) {
			$found_client++;
			$found_client_host++;
			last;
		}
	}

	my $found_client_range=0;
	# check the 'range' for dynamic addresses in the network ...
	my @dynamic_ips=();
	foreach my $r (@{$dhcp_hash->{subnet}->{$nw}->{range}}) {
		my ($start,$end)=split /\s+/, $r;
		my $start_dec=&convert_ip2dec($start);
		if ($end ne "") {
			my $end_dec=&convert_ip2dec($end);
			for (my $k=$start_dec;$k<=$end_dec;$k++) {
				push @dynamic_ips,$k;
			}
		} else {
			push @dynamic_ips,$start_dec;
		}
	}

	foreach my $d (@dynamic_ips) {
		if ($d ==  $client_ip_dec) {
			$found_client++;
			$found_client_range++;
			last;
		}
	}
	
	if (! $found_client) {
		print STDERR "$0: $client_ip does not exists.\n";
		exit 1;
	}

	if ($option{h}) {;}	# client hostname, it should actually add the hostname to the NIS/NIS+ or /etc/hosts table. IGNORE THIS
	if ($option{s}) {;}	# don't know what to do with -s, it's always the DHCP server itself for ISC DHCP

	my $comment='';
	if ($option{c} ne '') { 
		$comment=$option{c};
	}

	if ($option{e}) {
		# I don't know what to do with this option if this is a permanent entry ....
	}

	my $client_id=$option{i};
	my $harware_ethernet='';
	my $dhcp_client_identifier='';
	# what client id's can we have ?
	# 00 (Dynamic), 01AABBCCDDEEFF (01<MAC>), 00FF200008FFFFFFFFFFFFAABBCCDDEEFF, (group id + Mac) 

	if ($client_id ne '') {
		if ($option{I}) {
			$harware_ethernet=&convert_mac2generic($client_id);
			if (! &check_mac($client_id)) {
				print STDERR "$0: \"$client_id\" is not a valid mac address.\n";
				exit 1;
			}
		} else {
			my $l=length($client_id);
			if ($l%2) {
				print STDERR "$0: \"$client_id\" is not a valid client ID (needs even # of characters). (Or did you miss the -I option?)\n";
				exit 1;
			} elsif ($l > 14) { 
				# hey, probably an entry with a dhcp-client-identifier!
				# take the last 12 characters for the Mac address, and the rest for the dhcp-client-identifier
				# $dhcp_client_identifier=substr($client_id,0,$l-12);
				$dhcp_client_identifier=$client_id;
				$dhcp_client_identifier=~s/(.{2})/:\1/g;
				$dhcp_client_identifier=~s/^://;
				$harware_ethernet=&convert_mac2generic(substr($client_id,$l-12,12));
			} elsif ($l == 14) {
				$harware_ethernet=&convert_mac2generic(substr($client_id,$l-12,12));
			} elsif ($l == 12) {
				$harware_ethernet=&convert_mac2generic($client_id);
			} elsif ($client_id eq "00") {
				$dynamic_flag++;
			} else  {
				print STDERR "$0: \"$client_id\" is not a valid client id.\n";
				exit 1;
			} 
		}
		$harware_ethernet=lc($harware_ethernet);
		$dhcp_client_identifier=lc($dhcp_client_identifier);

		# check the hosts declarations if that hardware address is already there, delete it !
		foreach my $h (keys %{$dhcp_hash->{host}}) {
			if (lc($dhcp_hash->{host}->{$h}->{'hardware ethernet'}[0]) eq $harware_ethernet) {
				delete $dhcp_hash->{host}->{$h};
			}
		}
	}
	if ($option{u} ne '') {
		$dhcp_client_identifier=$option{u};
	}

	my $flags=uc($option{f});

	if ($flags =~ /[A-Z]+/) { 
		@flag_array=split /\+/, $flags;
		$flags=0;
		foreach my $f (@flag_array) {
			if ($f eq "DYNAMIC") {
				$flags+=0;
			} elsif ($f eq "PERMANENT") {
				$flags+=1;
			} elsif ($f eq "MANUAL") {
				$flags+=2;
			} elsif ($f eq "UNUSABLE") {
				$flags+=4;
			} elsif ($f eq "BOOTP") {
				$flags+=8;
			}
		}
	} 
	$flags+=0;

	$dynamic_flag++ if (! $flags );

	my $macro=$option{m};
	my $implied_macro=0;
	my $ippattern='^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$';
	if ($macro =~ /$ippattern/) {
		$implied_macro++;
	}

	my $Groupname="Group " . $macro;
	if ($macro ne '') {
		if ($implied_macro) {
			if (ref($dhcp_hash->{subnet}->{$nw}) ne "HASH") {
				print STDERR "$0: network $nw is not defined, implied macro will not work\n"; 
				exit 1;
			}
		} elsif (ref($dhcp_hash->{$Groupname}) ne "ARRAY") {
			print STDERR "$0: macro \"$macro\": does not exists.\n"; 
			exit 1;
		}
	}

	### so what are we actually changing, a host entry or a dynamic ip as a range ?
	if ($found_client_host) {
		# well, at least it's a host entry ....
		if ($harware_ethernet ne '') {
			$dhcp_hash->{host}->{$client_name}->{'hardware ethernet'}->[0]=$harware_ethernet;
		}
		if ($dhcp_client_identifier ne '') {
			$dhcp_hash->{host}->{$client_name}->{'dhcp-client-identifier'}->[0]=$dhcp_client_identifier;
		}
		if ($comment ne '') {
			$dhcp_hash->{host}->{$client_name}->{'item_comment'}->{this}="# " . $comment;
		}
		if ($macro ne '' and !$implied_macro) {
			$dhcp_hash->{host}->{$client_name}->{'group'}->[0]=$macro;
		}
	} 

	if ($found_client_range) {
		# add the entry in a range ...
		# use the array with dynamic ip addresses which was already created , BUT THEY ARE IN DECIMAL!!!

		@dynamic_ips=sort {$a <=> $b} @dynamic_ips;

		# rewrite the ranges ...
		delete $dhcp_hash->{subnet}->{$nw}->{range};

		my @range_group=();
		push @dynamic_ips,0;		# make the last entry ZERO 
		foreach my $array_counter (0 .. $#dynamic_ips) {
			push @range_group, &convert_dec2ip($dynamic_ips[$array_counter]);
			if ($dynamic_ips[$array_counter+1] != $dynamic_ips[$array_counter] + 1) {
				# seems that the next entry is NOT 1 higher, so write the range ...
				my $range='';
				last if ($range_group[0] eq "0.0.0.0");
				if ($#range_group > 0 ) {
					$range=$range_group[0] . " " . $range_group[$#range_group];
				} else {
					$range=$range_group[0];
				}
				push @{$dhcp_hash->{subnet}->{$nw}->{range}},$range;
				@range_group=();
			}
		}
		if ($comment ne '') {
		  	$dhcp_hash->{subnet}->{$nw}->{item_comment}->{range}->{$client_ip}="# " . $comment;
		}
	}
}

sub check_data_type {
	# check data_type of the value of the option, return new $value if needed 
	my ($opt,$val)=@_;
	$data_type=$dhcp4_inittab_hash->{$opt}->{data_type};

	if ($data_type =~ /ASCII/) {
		# be forgiving for the quotes ...
		if ($val !~ /^(["|'])(.*)(["|'])$/ ) {
			$val="\"" . $val . "\"";
		} 
	} elsif ($data_type =~ /NUMBER/) {
		# strip everything except the numbers
		$val=~s/([^0-9])//g;
		if ($val eq '') {
			print STDERR "$0: Symbol $opt is not a number.\n";
			exit 1;
		}
	} elsif ($data_type =~ /IP/) {
		my $ip_list='';
		foreach my $ip (split /\s+/,$val) {
			if (! &check_ip($ip,1)) { # check quietly ...
				print STDERR "$0: Value for symbol $opt is not an ip-address or a list of ip-addresses.\n";
				exit 1;
			}
		}
		$val=~s/\s+/,/g;		# replace spaces with a comma.
	} elsif ($data_type =~ /BOOL/) {
		# cool, but ISC doesn't deal with this ...
		print STDERR "$0: symbol $opt is not implemented.\n";
		exit 1;
	} elsif ($data_type =~ /OCTET/) {
		$val=~s/([^0-9])//g;
		foreach my $b (split /\\/,$val) {
			if (length($b) != 3 ) {
				print STDERR "$0: Value for symbol $opt is not a string of octets.\n";
				exit 1;
			} 
		}
	}
	return $val;
}

sub dhtadm_A {
	if ( (!$option{s} and !$option{d}) or (!$option{m} and !$option{d}) ) { 
		&dhtadm_usage;
		exit 1;
	}

	if ($option{s} and !$option{d}) {
		# symbol and definition ...
		print STDERR "$0: Sorry, defining symbols not implemented yet\n";
		exit 1;
	}

	# adding MACRO's
	if ($option{m} and $option{d}) {
		# macro and definition ...
		my $macro=$option{m};
		my $definition=$option{d};

		$macro=&trim($macro);
		$definition=&trim($definition);

		if ($debug) {
			print "Macro: $macro\n";
			print "Def:   $definition\n";
		}

		if ($option{d} !~ /^:.*:$/ ) {
			print STDERR "$0: The macro, $macro, contains a definition syntax error\n"; 
			exit 1;
		}  

		$definition=~s/^://;
		$definition=~s/:$//;

		my $macro_name="Group " . $macro;

		# exit with errno 1 if macro already exist
		if (ref($dhcp_hash->{$macro_name}) eq "ARRAY") {
			print STDERR "$0: macro $macro already exists.\n"; 
			exit 1;
		}
		

		# Make a hash for the options that are defined. In Solaris DHCP terms they are called 'symbols'
		# the sysmbols should have been defined in option, and the contents are in an array ...
		# a dump would be:
		# 'option' => [
		#	'space SUNW',
		#	'SUNW.SrootOpt code 1 = text',
		#	'SUNW.SrootIP4 code 2 = ip-address',
		#	'SUNW.SrootNM code 3 = text',
		#	'SUNW.SrootPTH code 4 = text',
		#	'SUNW.SswapIP4 code 5 = ip-address',
		#	'SUNW.SswapPTH code 6 = text',
		#	'SUNW.SbootFIL code 7 = text',
		#	'SUNW.Stz code 8 = text',
		#	'SUNW.SbootRS code 9 = unsigned integer 16',
		#	'SUNW.SinstIP4 code 10 = ip-address',
		#	'SUNW.SinstNM code 11 = text',
		#	'SUNW.SinstPTH code 12 = text',
		#	'SUNW.SsysidCF code 13 = text',
		#	'SUNW.JumpStart-server code 14 = text',
		#	'SUNW.Sterm code 15 = text',
		#	'SUNW.SbootURI code 16 = text',
		#	'SUNW.SHTTPproxy code 17 = text'
		#	],
		# the FIRST entry MUST be the space, and the rest the new named symbol, with the SUNW. to make it kind of unique ...
		# For Solaris users, you would only enter the sysbol AFTER the SUNW. definition, so we have to look up what the
		# match would be:
		# if I ask for SswapPTH, I actually mean SUNW.SswapPTH for the option in the dhcpd4.conf file.

		my $symbols_hash;
		foreach my $a (@{$dhcp_hash->{option}}) {
			if ($a =~ /^space/) {
				my ($dummy,$the_space_name)=split /\s+/,$a;
				$symbols_hash->{$the_space_name}->{space}=1;
			} else {
				my ($s,$symbol)=split /\./,$a,2;
				$symbol=~s/\s+.*$//;
				if ($symbols_hash->{$s}) {
					$symbols_hash->{$s}->{$symbol}=$symbol;
				}
			}
		}
		# print Dumper($symbols_hash);

		$macro_content;

		# make sure that if the entries itself has colons and are quoted, my split will work ...
		# $definition=~s/("[^:]*):([^"]*")/$1CoLoN$2/g;
		# $definition=~s/('[^:]*):([^']*')/$1CoLoN$2/g;
		# oops, only the first ':' will be replaced ...
		$definition=~s/("[^"]+")/(my $part_between_quotes = $1)=~s!:!CoLoN!g; $part_between_quotes/ge;
		$definition=~s/('[^']+')/(my $part_between_quotes = $1)=~s!:!CoLoN!g; $part_between_quotes/ge;

		foreach my $o (split /:/, $definition) {
			$o=~s/CoLoN/:/g;
			my ($opt,$val)=split /=/, $o;
			$opt=&trim($opt);
			$val=&trim($val);

			if ($opt eq '') {
				print STDERR "$0: The macro, $macro, contains a definition syntax error\n"; 
				exit 1;
			}

			if ($val eq '') {
				print STDERR "$0: Symbol $opt needs a value.\n"; 
				exit 1;
			}

			my $found=0;
			### Special is the Include (add another macro).
			### This is VERY tricky, because you cannot refer to it in the dhcpd4.conf file if the Macro
			### Group XXXXX { ...} has not been read yet!
			# Lets' ignore that for now, and just make sure the include macro exists ... 
			# and yes, Solaris DHCP just adds this, without bothering the include exists. 
			# I don't know the consequences for Solaris DHCP, but for ISC it's not good ;-)

			if (ucfirst($opt) eq 'Include') {
				# a lot of scripts still have the 'Include:10.10.10.0', like including a network. 
				# if That is the  the case, just ignore this, because it's included anyway ;-)
				my $ippattern='^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$';
				if ($val =~ /$ippattern/ and ref($dhcp_hash->{subnet}->{$val}) eq "HASH") {
					# oh, seems to be ok, do nothing just ignore it...
					print STDERR "$0: Note: Includes for networks is implied, keyword and value are not needed, continuing without error.\n";
					next;
				} else {
					my $incude_group_name="Group " . $val;
					if (ref($dhcp_hash->{$incude_group_name}) ne "ARRAY") {
						print STDERR "$0: Cannot use 'Include' on macro '$val' because it does not exist.\n";
						exit 1;
					}
				}
			} 

			# check the data type of the option ...
			$val=&check_data_type($opt,$val); 

			if ($solaris_2_isc_options->{$opt} ne '') {
				my $a="option " . $solaris_2_isc_options->{$opt};
				if ($dhcp4_inittab_hash->{$opt}->{category} eq "FIELD") {
					# Don't call it an option, it's an internal thingy (whatever that is ...)
					$a=$solaris_2_isc_options->{$opt};
				}
				push @{$macro_content->{$a}},$val;
				$found++;
			} elsif (ucfirst($opt) eq 'Include') {
				### well................ never mind, the 'Include' doesn't work inside a named group anyway!!!
				my $ippattern='^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$';
				print STDERR "$0: Sorry, Includes in a macro does not work in ISC DHCP (calling macro in a macro).\n";
				exit 1;
				### push @{$macro_content->{'group'}},$val;
				### $found++;
			} else {
				# try to find this option in the symbols hash ...
				foreach my $space (keys %{$symbols_hash}) {
					if ($opt eq $symbols_hash->{$space}->{$opt}) {
						my $a="option " . $space . "." . $opt;
						push @{$macro_content->{$a}},$val;
						$found++;
						last;
					}
				}
			}
			if (! $found) {
				print STDERR "$0: The $opt is an invalid option or is not of the correct type (did you forget quotes?)\n";
				exit 1;
			}
		} 
		push @{$dhcp_hash->{$macro_name}},$macro_content;
	}
}


sub dhtadm_D {
	if ( !$option{s} and !$option{m} ) { 
		&dhtadm_usage;
		exit 1;
	}

	# deleting MACRO's
	if ($option{m}) {
		# macro and definition ...
		my $macro=$option{m};

		$macro=&trim($macro);

		if ($debug) {
			print "Macro: $macro\n";
		}

		my $macro_name="Group " . $macro;

		# exit with errno 1 if macro does NOT exist
		if (ref($dhcp_hash->{$macro_name}) ne "ARRAY") {
			print STDERR "$0: macro \"$macro\": does not exists.\n"; 
			exit 1;
		}
		
		# exit with errno 1 if macro is used by a host or something 
		# and hey, they can only be DEFINED in a host declaration !!!!!!
		foreach my $h (keys %{$dhcp_hash->{host}}) {
			if ($dhcp_hash->{host}->{$h}->{group}[0] eq "$macro") {
				print STDERR "$0: Cannot delete macro $macro because it is used in host declaration $h.\n"; 
				exit 1;
			}
		}

		delete $dhcp_hash->{$macro_name};
	}
}

sub dhtadm_M {
	# let's split the functions for modifying symbol and macro... 
	if ($option{m}) {
		&dhtadm_Mm;
	}
	if ($option{s}) {
		print STDERR "$0: Sorry, modifiying symbols not implemented yet!\n";
		exit1;
	}
}

sub translate_isc_macro_to_solaris_macro {
	# translate ISC options and internal names to Solaris Symbols
	# returns an array and a definition string

	my ($ret_type,$macro_hash)=@_;		# if ret_type is "array" return the definition array otherwise the string (needed for dhtadm_P

	my $symbols_hash;
	foreach my $a (@{$dhcp_hash->{option}}) {
		if ($a =~ /^space/) {
			my ($dummy,$the_space_name)=split /\s+/,$a;
			$symbols_hash->{$the_space_name}->{space}=1;
		} else {
			my ($s,$symbol)=split /\./,$a,2;
			$symbol=~s/\s+.*$//;
			if ($symbols_hash->{$s}) {
				$symbols_hash->{$s}->{$symbol}=$symbol;
			}
		}
	}

	my @definition_array=();
	foreach my $k (keys %{$macro_hash} ) {
		if ($k eq 'option') {
			foreach my $l (@{$macro_hash->{$k}} ) {
				my ($o,$v)=split /\s+/, $l;
				$v=~s/,/ /g;
				# check if this is a vendor specfic option, see $symbols_hash
				my ($vendor_id,$vendor_symbol)=split /\./,$o;
				if ($symbols_hash->{$vendor_id}->{$vendor_symbol} ne '') {
					$solaris_symbol=$vendor_symbol;
				} else {
					$solaris_symbol=$isc_2_solaris_options->{$o};
				}
				if ($solaris_symbol eq '') {
					print STDERR "$0: option $o, has no Solaris equivalent?\n";
					next;
				}
				push @definition_array,[$solaris_symbol,$v];
			}
		} elsif ($k eq 'item_comment' or $k eq 'line_comments' or $k eq 'range') {
			next;
		} else {
			my $v=$macro_hash->{$k}->[0];
			$v=~s/,/ /g;
			# check if this is a vendor specfic option, see $symbols_hash
			my ($vendor_id,$vendor_symbol)=split /\./,$k;
			if ($symbols_hash->{$vendor_id}->{$vendor_symbol} ne '') {
				$solaris_symbol=$vendor_symbol;
			} else {
				$solaris_symbol=$isc_2_solaris_options->{$k};
			}
			if ($solaris_symbol eq '' and $k ne 'default-lease-time') {
				if ($k ne 'netmask') {
					print STDERR "$0: option $k, has no Solaris equivalent?\n";
				}
				next;
			}
			push @definition_array,[$solaris_symbol,$v];
		}
	}

	if ($ret_type eq "array") {
		return @definition_array;
	} else {
		my $ret_str=":";
		foreach my $i (@definition_array) {
			my ($o,$v)=@$i;
			$ret_str.=$o . "=" . $v . ":";
		}
		return ($ret_str);
	}
}

sub dhtadm_Mm {
	# check for the other options, only one of the 3 options are allowed: n | d | e
	$extra_option_counter=0;
	for my $o ('n','d','e') {
		$extra_option_counter++ if ($option{$o});
	}
	if ($extra_option_counter != 1) {
		dhtadm_usage();
		exit 1;
	}

	# exit (errno=1) if macro does not exist
	my $macro=$option{m};
	$macro=&trim($macro);

	my $implied_macro=0;
	### my $ippattern='^\d{1,3}_\d{1,3}_\d{1,3}_\d{1,3}$'; 				# no underscores, just the network with dots, like 10.10.1.1
	my $ippattern='^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$';
	my $nw=$macro;
	### $nw=~s/_/\./g;								# no underscores, just the network with dots, like 10.10.1.1
	if ($macro =~ /$ippattern/) {
		$implied_macro++;
	}

	my $macro_name="Group " . $macro;
	if ($implied_macro) {
		if (ref($dhcp_hash->{subnet}->{$nw}) ne "HASH") {
			print STDERR "$0: network $nw is not defined, implied macro will not work\n"; 
			exit 1;
		}
	} elsif (ref($dhcp_hash->{$macro_name}) ne "ARRAY") {
		print STDERR "$0: macro \"$macro\": does not exists.\n"; 
		exit 1;
	}

	my $symbols_hash;
	foreach my $a (@{$dhcp_hash->{option}}) {
		if ($a =~ /^space/) {
			my ($dummy,$the_space_name)=split /\s+/,$a;
			$symbols_hash->{$the_space_name}->{space}=1;
		} else {
			my ($s,$symbol)=split /\./,$a,2;
			$symbol=~s/\s+.*$//;
			if ($symbols_hash->{$s}) {
				$symbols_hash->{$s}->{$symbol}=$symbol;
			}
		}
	}
	# print Dumper($symbols_hash);


	# modifying macro, changing the whole definition
	if ($option{d}) {
		# macro and definition ...
		my $definition=$option{d};
		$definition=&trim($definition);

		if ($debug) {
			print "Macro: $macro\n";
			print "Def:   $definition\n";
		}

		if ($option{d} !~ /^:.*:$/ ) {
			print STDERR "$0: The macro, $macro, contains a definition syntax error\n"; 
			exit 1;
		}  

		$definition=~s/^://;
		$definition=~s/:$//;


		$macro_content;

		# make sure that if the entries itself has colons and are quoted, my split will work ...
		# $definition=~s/("[^:]*):([^"]*")/$1CoLoN$2/g;
		# $definition=~s/('[^:]*):([^']*')/$1CoLoN$2/g;
		# oops, only the first ':' will be replaced ...
		$definition=~s/("[^"]+")/(my $part_between_quotes = $1)=~s!:!CoLoN!g; $part_between_quotes/ge;
		$definition=~s/('[^']+')/(my $part_between_quotes = $1)=~s!:!CoLoN!g; $part_between_quotes/ge;
		foreach my $o (split /:/, $definition) {
			$o=~s/CoLoN/:/g;
			my ($opt,$val)=split /=/, $o;
			$opt=&trim($opt);
			$val=&trim($val);

			if ($opt eq '') {
				print STDERR "$0: The macro, $macro, contains a definition syntax error\n"; 
				exit 1;
			}

			if ($val eq '') {
				print STDERR "$0: Symbol $opt needs a value.\n"; 
				exit 1;
			}

			my $found=0;
			### Special is the Include (add another macro).
			### This is VERY tricky, because you cannot refer to it in the dhcpd4.conf file if the Macro
			### Group XXXXX { ...} has not been read yet!
			# Lets' ignore that for now, and just make sure the include macro exists ... 
			# and yes, Solaris DHCP just adds this, without bothering the include exists. 
			# I don't know the consequences for Solaris DHCP, but for ISC it's not good ;-)

			if (ucfirst($opt) eq 'Include') {
				# a lot of scripts still have the 'Include:10.10.10.0', like including a network. 
				# if That is the  the case, just ignore this, because it's included anyway ;-)
				my $ippattern='^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$';
				if ($val =~ /$ippattern/ and ref($dhcp_hash->{subnet}->{$val}) eq "HASH") {
					# oh, seems to be ok, do nothing just ignore it...
					print STDERR "$0: Note: Includes for networks is implied, keyword and value are not needed, continuing without error.\n";
					next;
				} else {
					my $incude_group_name="Group " . $val;
					if (ref($dhcp_hash->{$incude_group_name}) ne "ARRAY") {
						print STDERR "$0: Cannot use 'Include' on macro '$val' because it does not exist.\n";
						exit 1;
					}
				}
			} 

			# check the data type of the option ...
			$val=&check_data_type($opt,$val); 

			if ($solaris_2_isc_options->{$opt} ne '') {
				my $a="option " . $solaris_2_isc_options->{$opt};
				if ($dhcp4_inittab_hash->{$opt}->{category} eq "FIELD") {
					# Don't call it an option, it's an internal thingy (whatever that is ...)
					$a=$solaris_2_isc_options->{$opt};
				}
				push @{$macro_content->{$a}},$val;
				$found++;
			} elsif (ucfirst($opt) eq 'Include') {
				### well................ never mind, the 'Include' doesn't work inside a named group anyway!!!
				print STDERR "$0: Sorry, Includes in a macro does not work in ISC DHCP (calling macro in a macro).\n";
				exit 1;
				### push @{$macro_content->{'group'}},$val;
				### $found++;
			} else {
				# try to find this option in the symbols hash ...
				foreach my $space (keys %{$symbols_hash}) {
					if ($opt eq $symbols_hash->{$space}->{$opt}) {
						my $a="option " . $space . "." . $opt;
						push @{$macro_content->{$a}},$val;
						$found++;
						last;
					}
				}
			}
			if (! $found) {
				print STDERR "$0: The $opt is an invalid option or is not of the correct type (did you forget quotes?)\n";
				exit 1;
			}
		} 
		if ($implied_macro) {
			foreach my $k (keys %{$dhcp_hash->{subnet}->{$nw}}) {
				if ($k eq 'line_comments' or $k eq 'item_comment' or $k eq 'netmask' or $k eq 'range') {
					$macro_content->{$k}=$dhcp_hash->{subnet}->{$nw}->{$k};
				}
			}
			delete $dhcp_hash->{subnet}->{$nw};
			$dhcp_hash->{subnet}->{$nw}=$macro_content;
		} else {
			delete $dhcp_hash->{$macro_name};
			push @{$dhcp_hash->{$macro_name}},$macro_content;
		}
	}

	# modifying macro, changing/adding/deleting only 1 symbol
	# if the symbol exists, change it. 
	# if the symbol does not exists, add it.
	# if the value of the symbol is empty, delete it, if it does not exists, errormg="The $opt option is an invalid option or is not of the correct type"
	if ($option{e}) {
		my ($opt,$val)=split /=/, $option{e};
		$opt=&trim($opt);
		$val=&trim($val);

		if ($opt eq '') {
			print STDERR "$0: The macro, $macro, contains a definition syntax error\n"; 
			exit 1;
		}

		my @definition_array=();
		# 'translate' the existing options back to solaris DHCP language
		if ($implied_macro) {
			@definition_array=&translate_isc_macro_to_solaris_macro("array",$dhcp_hash->{subnet}->{$nw});  
		} else {
			@definition_array=&translate_isc_macro_to_solaris_macro("array",$dhcp_hash->{$macro_name}->[0]);  
		}

		my $symbol_found=-1;
		foreach my $i (0 .. $#definition_array) {
			my ($o,$v)=@{$definition_array[$i]};
			if ($o eq $opt) {
				$definition_array[$i][1]=$val;
				$symbol_found=$i;
				last;
			}
		}

		if ($symbol_found > -1 and $val eq '') {
			print "Deleting  $definition_array[$symbol_found][0]\n";
			splice (@definition_array,$symbol_found,1);
		}

		if ($symbol_found == -1) {
			push @definition_array,[$opt,$val];
		}

		# write the whole stuff back ....
		my $macro_content;
		foreach my $i (@definition_array) {
			my ($o,$v)=@$i;
			next if ($v eq '');
			my $found=0;
			if (ucfirst($opt) eq 'Include') {
				# a lot of scripts still have the 'Include:10.10.10.0', like including a network. 
				# if That is the  the case, just ignore this, because it's included anyway ;-)
				my $ippattern='^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$';
				if ($v =~ /$ippattern/ and ref($dhcp_hash->{subnet}->{$v}) eq "HASH") {
					# oh, seems to be ok, do nothing just ignore it...
					print STDERR "$0: Note: Includes for networks is implied, keyword and value are not needed, continuing without error.\n";
					next;
				} else {
					my $incude_group_name="Group " . $v;
					if (ref($dhcp_hash->{$incude_group_name}) ne "ARRAY") {
						print STDERR "$0: Cannot use 'Include' on macro '$v' because it does not exist.\n";
						exit 1;
					}
				}
			} 

			# check the data type of the option ...
			$v=&check_data_type($o,$v); 

			if ($solaris_2_isc_options->{$o} ne '') {
				my $a="option " . $solaris_2_isc_options->{$o};
				if ($dhcp4_inittab_hash->{$opt}->{category} eq "FIELD") {
					# Don't call it an option, it's an internal thingy (whatever that is ...)
					$a=$solaris_2_isc_options->{$o};
				}
				push @{$macro_content->{$a}},$v;
				$found++;
			} elsif (ucfirst($opt) eq 'Include') {
				### well................ never mind, the 'Include' doesn't work inside a named group anyway!!!
				print STDERR "$0: Sorry, Includes in a macro does not work in ISC DHCP (calling macro in a macro).\n";
				exit 1;
				### push @{$macro_content->{'group'}},$v;
				### $found++;
			} else {
				# try to find this option in the symbols hash ...
				foreach my $space (keys %{$symbols_hash}) {
					if ($o eq $symbols_hash->{$space}->{$o}) {
						my $a="option " . $space . "." . $o;
						push @{$macro_content->{$a}},$v;
						$found++;
						last;
					}
				}
			}
			if (! $found) {
				print STDERR "$0: The $o is an invalid option or is not of the correct type (did you forget quotes?)\n";
				exit 1;
			}
		} 
		if ($implied_macro) {
			foreach my $k (keys %{$dhcp_hash->{subnet}->{$nw}}) {
				if ($k eq 'line_comments' or $k eq 'item_comment' or $k eq 'netmask' or $k eq 'range') {
					$macro_content->{$k}=$dhcp_hash->{subnet}->{$nw}->{$k};
				}
			}
			delete $dhcp_hash->{subnet}->{$nw};
			$dhcp_hash->{subnet}->{$nw}=$macro_content;
		} else {
			delete $dhcp_hash->{$macro_name};
			push @{$dhcp_hash->{$macro_name}},$macro_content;
		}
	}
	if ($option{n}) {
		# rename the macro.
		my $new_macro=$option{n};

		my $new_macro_name="Group " . $new_macro;
		# exit with errno 1 if new_macro already exist
		if (ref($dhcp_hash->{$new_macro_name}) eq "ARRAY") {
			print STDERR "$0: Cannot rename macro, macro $new_macro already exists.\n"; 
			exit 1;
		}

		$new_macro=&trim($new_macro);
		foreach my $h (keys %{$dhcp_hash->{host}}) {
			if ($dhcp_hash->{host}->{$h}->{group}[0] eq "$macro") {
				$dhcp_hash->{host}->{$h}->{group}[0]=$new_macro;
				last;
			}
		}

		my $macro_hash=$dhcp_hash->{$macro_name}->[0];
		delete $dhcp_hash->{$macro_name};
		push @{$dhcp_hash->{$new_macro_name}},$macro_hash;
	}
}

sub dhtadm_P {
	# display the dhcptab ..
	my @dhtptab=();

	my $max_name_length=0;

	### network options (implied macro)
	foreach my $nw (keys %{$dhcp_hash->{subnet}}) {
		my $m=$nw;
		# $m=~s/\./_/g;					# no underscores, just the network with dots, like 10.10.1.1
		$m=$m . "*";
		my $l=length($m);
		$max_name_length=$l if ($l > $max_name_length);
		$definition=&translate_isc_macro_to_solaris_macro("string",$dhcp_hash->{subnet}->{$nw});
		push @dhtptab,[$m,"Macro*",$definition];
	}

	foreach my $k (sort keys %{$dhcp_hash} ) {
		next if ($k !~ /^Group\s+/ );
		my $m=$k;
		$m=~s/^Group\s+//;
		my $l=length($m);
		$max_name_length=$l if ($l > $max_name_length);
		$definition=&translate_isc_macro_to_solaris_macro("string",$dhcp_hash->{$k}->[0]);
		push @dhtptab,[$m,"Macro",$definition];
	}

	my $symbols_hash;
	foreach my $a (@{$dhcp_hash->{option}}) {
		if ($a =~ /^space/) {
			my ($dummy,$the_space_name)=split /\s+/,$a;
			$symbols_hash->{$the_space_name}->{space}=1;
		} else {
			my ($o,$v)=split /\s+/,$a,2;
			my ($s,$symbol)=split /\./,$o,2;
			$symbol=~s/\s+.*$//;
			if ($symbols_hash->{$s}) {
				my $l=length($o);
				$max_name_length=$l if ($l > $max_name_length);
				$symbols_hash->{$s}->{$symbol}=$v;
				push @dhtptab,[$o,"Symbol",$v];
			}
		}
	}

	printf("%-${max_name_length}s  %-6s  %s\n","Name","Type","Value");
	print "=" x 40,"\n";

	foreach my $i (@dhtptab) {
		my ($name,$type,$value)=@$i;
		printf("%-${max_name_length}s  %-6s  %s\n",$name,$type,$value);
	}

	print "\n";
	print "NOTE: * marked macro's are implied. They do NOT exist per se, but are part of the network declarations\n";
} 

sub save_old_config_file {
	### this routine will save a copy of the configuration file, including timestamp.
	### if something goes wrong, like a error in the file that prevents the dhcpd to start
	### you can always go back to the latest working copy. 
	### Let's keep the number of copies limited to $nr_of_backups (see config.pm)
	
	# how many files do we have ?
	my @bu_array=reverse sort glob("/tmp/dhcpd.conf.bak.*");
	$nr_of_backups--;
	if ($#bu_array >= $nr_of_backups) {
		for (my $k=$nr_of_backups;$k<=$#bu_array;$k++) {
			unlink $bu_array[$k];
		} 
	} 

	my $bu_file="/tmp/dhcpd.conf.bak." . &mytimestamp();
	if (-f "$bu_file" ) {
		# make it more unique ;-)
		$bu_file.=join("", ('a'..'z','A'..'Z',0..9)[map rand $_, (62)x16]);
	}
	open(CFILE,"$dhcpd4_conf_file") or die "Cannot open \"$dhcpd4_conf_file\" for read: $!\n";
	open(BU,">$bu_file") or die "Cannot open \"$bu_file\" for write: $!\n";
	print BU <CFILE>;
	close BU;
	close CFILE;
}

sub check_service_state {
	# return 0 if dhcp deamon is not running
	# return 1 if ok.
	my ($silent)=@_;

	my $os=`uname -s`;chomp $os;
	if ($os eq "SunOS") {
		my $state='';
		my $stime='';
		# solaris with SMF:
		open(CMD,"/usr/bin/svcs svc:/network/dhcp/server:ipv4 2>&1|");
		@data=<CMD>;
		close CMD;
		foreach my $l (@data) {
			chomp $l;
			next if ($l =~ /^STATE/);
			if ($l =~ /^(\w+)(\s+)([A-Za-z0-9:_]+)(\s+)(svc.*$)/ ) {
				$state=$1;
				$stime=$3;
			}
			if ($state ne 'online') {
				print STDERR "WARNING: dhcpd4 status is in $state mode since $stime. Operator intervention is needed. \n" if ($silent ne 'silent');
				return 0;
			}
		}
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
			$cmd=$service_script . " status";
			open(CMD,"$cmd|");
			@data=<CMD>;
			close CMD;
			foreach my $l (@data) {
				chomp $l;
				next if ($l =~ /^STATE/);
				if ($l =~ /stopped/i or $l =~ /not running/i) {
					print STDERR "WARNING: dhcpd4 status not running. Operator intervention is needed. \n" if ($silent ne 'silent');
					return 0;
				}
			}
		} else {
			print STDERR "OOPS! Cannot find a command to start/stop/restart the dhcp service!\n";
			return 0;
		}
	}
	return 1;
}

1;
