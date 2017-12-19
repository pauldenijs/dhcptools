# option names for ISC DHCP vs Solaris DHCP
# all option names should be translated to ISC options
#

@ISC_vs_Solaris_DHCPOptions_array=(
['Tag',	'Name',							'ISC',						'Solaris'	],
['1',	'Subnet Mask',						'subnet-mask',					'Subnet'	],
['2',	'Time Offset',						'time-offset',					'UTCoffst'	],
['3',	'Router (Default Gateway)',				'routers',					'Router'	],
['4',	'Time Server',						'time-servers',					'Timeserv'	],
['5',	'Name Server',						'ien116-name-servers',				'IEN116ns'	],
['6',	'Domain Server',					'domain-name-servers',				'DNSserv'	],
['7',	'Log Server',						'log-servers',					'Logserv'	],
['8',	'Quotes Server',					'cookie-servers',				'Cookie'	],
['9',	'LPR Server',						'lpr-servers',					'Lprserv'	],
['10',	'Impress Server',					'impress-servers',				'Impress'	],
['11',	'RLP Server',						'resource-location-servers',			'Resource'	],
['12',	'Hostname',						'host-name',					'Hostname'	],
['13',	'Boot File Size',					'boot-size',					'Bootsize'	],
['14',	'Merit Dump File',					'merit-dump',					'Dumpfile'	],
['15',	'Domain Name',						'domain-name',					'DNSdmain'	],
['16',	'Swap Server',						'swap-server',					'Swapserv'	],
['17',	'Root Path',						'root-path',					'Rootpath'	],
['18',	'Extension File',					'extensions-path',				'ExtendP'	],
['19',	'Forward On/Off',					'ip-forwarding',				'IpFwdF'	],
['20',	'Source Routing',					'non-local-source-routing',			'NLrouteF'	],
['21',	'Policy Filter',					'policy-filter',				'PFilter'	],
['22',	'Max Datagram Size for Reassembly',			'max-dgram-reassembly',				'MaxIpSiz'	],
['23',	'Default IP TTL',					'default-ip-ttl',				'IpTTL'		],
['24',	'MTU Timeout',						'path-mtu-aging-timeout',			'PathTO'	],
['25',	'MTU Plateau',						'path-mtu-plateau-table',			'PathTbl'	],
['26',	'MTU Interface',					'interface-mtu',				'MTU'		],
['27',	'MTU Subnet',						'all-subnets-local',				'SameMtuF'	],
['28',	'Broadcast Address',					'broadcast-address',				'Broadcst'	],
['29',	'Mask Discovery',					'perform-mask-discovery',			'MaskDscF'	],
['30',	'Mask Supplier',					'mask-supplier',				'MaskSupF'	],
['31',	'Router Discovery',					'router-discovery',				'RDiscvyF'	],
['32',	'Router Request',					'router-solicitation-address',			'RSolictS'	],
['33',	'Static Route',						'static-routes',				'StaticRt'	],
['34',	'Trailers',						'trailer-encapsulation',			'TrailerF'	],
['35',	'ARP Timeout',						'arp-cache-timeout',				'ArpTimeO'	],
['36',	'Ethernet',						'ieee802-3-encapsulation',			'EthEncap'	],
['37',	'Default TCP TTL',					'default-tcp-ttl',				'TcpTTL'	],
['38',	'Keepalive Time',					'tcp-keepalive-interval',			'TcpKaInt'	],
['39',	'Keepalive Data',					'tcp-keepalive-garbage',			'TcpKaGbF'	],
['40',	'NIS Domain',						'nis-domain',					'NISdmain'	],
['41',	'NIS Servers',						'nis-servers',					'NISservs'	],
['42',	'NTP Servers',						'ntp-servers',					'NTPservs'	],
['43',	'Vendor Specific',					'vendor-encapsulated-options',			''		],
['44',	'NETBIOS Name Server',					'netbios-name-servers',				'NetBNms'	],
['45',	'NETBIOS Dist Server',					'netbios-dd-server',				'NetBDsts'	],
['46',	'NETBIOS Node Type',					'netbios-node-type',				'NetBNdT'	],
['47',	'NETBIOS Scope',					'netbios-scope',				'NetBScop'	],
['48',	'X Window Font',					'font-servers',					'XFontSrv'	],
['49',	'X Window Manager',					'x-display-manager',				'XDispMgr'	],
['50',	'Address Request',					'dhcp-requested-address',			''		],
#### This option is an overwrite, ISC dhcp uses 'default-lease-time' and 'max-lease-time' and the are INTERNAL 
#### So for the equivalent of LeaseTim, we take the ISC default-lease-time (INTERNAL NAME)  
['51',	'Address Time',						'max-lease-time',				'LeaseTim'	],
['52',	'Overload',						'dhcp-option-overload',				''		],
['53',	'DHCP Message Type',					'dhcp-message-type',				''		],
['54',	'DHCP Server Identifier',				'dhcp-server-identifier',			''		],
['55',	'Parameter List',					'dhcp-parameter-request-list',			''		],
['56',	'DHCP Message',						'dhcp-message',					'Message'	],
['57',	'DHCP Max Msg Size',					'dhcp-max-message-size',			''		],
['58',	'Renewal Time',						'dhcp-renewal-time',				'T1Time'	],
['59',	'Rebinding Time',					'dhcp-rebinding-time',				'T2Time'	],
['60',	'Vendor Class Id',					'vendor-class-identifier',			''		],
['61',	'Client Id',						'dhcp-client-identifier',			''		],
['62',	'Netware/IP Domain',					'nwip-domain',					'NW_dmain'	],
['64',	'NIS+ Domain Name',					'nisplus-domain',				'NIS+dom'	],
['65',	'NIS+ Server Address',					'nisplus-servers',				'NIS+serv'	],
['66',	'Server Name',						'tftp-server-name',				'TFTPsrvN'	],
['67',	'Bootfile Name',					'bootfile-name',				'OptBootF'	],
['68',	'Home Agent Addresses',					'mobile-ip-home-agent',				'MblIPAgt'	],
['69',	'SMTP Server',						'smtp-server',					'SMTPserv'	],
['70',	'POP3 Server',						'pop-server',					'POP3serv'	],
['71',	'NNTP Server',						'nntp-server',					'NNTPserv'	],
['72',	'WWW Server',						'www-server',					'WWWservs'	],
['73',	'Finger Server',					'finger-server',				'Fingersv'	],
['74',	'IRC Server',						'irc-server',					'IRCservs'	],
['75',	'StreetTalk Server',					'streettalk-server',				'STservs'	],
['76',	'StreetTalk Directory Assistance (STDA) Server',	'Streettalk-directory-assistance-server',	'STDAservs'	],
['77',	'User Class',						'user-class'				,	'UserClas'	],
['78',	'Service Location Protocol (SLP) Directory Agent',	'slp-directory-agent',				'SLP_DA'	],
['79',	'SLP Service Scope',					'slp-service-scope',				'SLP_SS'	],
['80',	'Rapid Commit',						'',						''		],
['81',	'Client FQDN',						'fqdn option space',				'FQDN'		],
['82',	'Relay Agent Information',				'agent.circuit-id',				'AgentOpt'	],
['83',	'iSNS',							'Not natively supported',			''		],
['85',	'NDS Servers',						'nds-servers',					''		],
['86',	'NDS Tree Name',					'nds-tree-name',				''		],
['87',	'NDS Context',						'nds-context',					''		],
['88',	'BCMCS Controller Domain Name',				'bcms-controller-names',			''		],
['89',	'BCMCS Controller Ipv4 address option',			'bcms-controller-address',			''		],
['90',	'Authentication',					'',						''		],
['91',	'Client-last-transaction-time option',			'',						''		],
['92',	'Associated-ip option',					'',						''		],
['93',	'Client System',					'',						'PXEarch'	],
['94',	'Client NDI',						'',						'PXEnii'	],
['95',	'LDAP',							'Not natively supported',			''		],
['97',	'UUID/GUID',						'',						'PXEcid'	],
['98',	'User Authentication Servers',				'uap-servers',					''		],
['99',	'GEOCONF_ CIVIC',					'Not natively supported',			''		],
['112',	'Netinfo Address',					'netinfo-server-address',			''		],
['113',	'Netinfo Tag',						'netinfo-server-tag',				''		],
['114',	'Default URL',						'default-url',					''		],
['116',	'Auto-Config',						'',						''		],
['117',	'Name Service Search',					'Not natively supported',			''		],
['118',	'Subnet Selection Option',				'subnet-selection',				''		],
['119',	'Domain Search',					'domain-search',				''		],
['120',	'SIP Servers DHCP Option',				'Not natively supported',			''		],
['121',	'Classless Static Route Option',			'Not natively supported',			''		],
['122',	'CCC',							'Not natively supported',			''		],
['123',	'GeoConf Option',					'Not natively supported',			''		],
['124',	'Vendor Identified Vendor Class',			'',						''		],
['125',	'Vendor Identified Vendor-Specific Information',	'vivso',					''		],
['0',	'',							'filename',					'BootFile'	],
['0',	'',							'',						'BootPath'	],
['0',	'',							'next-server',					'BootSrvA'	],
['0',	'',							'tftp-server-name',				'BootSrvN'	],
['0',	'',							'',						'EchoVC'	],
['0',	'',							'',						'LeaseNeg'	],
['0',	'',							'',						'Include'	],

### Added 2014-04-04, option for iSCSI, must be added manually in ISC DHCP as:
###       option iscsi-initiator-iqn code 203 = string;
### and in Legacy Solaris DHCP as:
###       dhtadm -A -s iSCSIiqn -d 'Site,203,ASCII,1,0' 
### Resulting in the following translation:
['203',	'iSCSI Initiator IQN',					'iscsi-initiator-iqn',				'iSCSIiqn'	],
);

$isc_2_solaris_options;	# named hash..
$solaris_2_isc_options;	# named hash..
foreach my $i (@ISC_vs_Solaris_DHCPOptions_array) {
	my ($nr,$descr,$isc_option,$solaris_option)=@$i;
	$isc_2_solaris_options->{$isc_option}=$solaris_option if ($isc_option ne '');
	$solaris_2_isc_options->{$solaris_option}=$isc_option if ($solaris_option ne '');
}

# The array below comes from a Solaris /etc/dhcp/inittab file
@dhcp4_inittab_array=(
['Subnet',		'STANDARD',	'1',		'IP',		'1',		'1',		'sdmi']	,
['UTCoffst',		'STANDARD',	'2',		'SNUMBER32',	'1',		'1',		'sdmi']	,
['Router',		'STANDARD',	'3',		'IP',		'1',		'0',		'sdmi']	,
['Timeserv',		'STANDARD',	'4',		'IP',		'1',		'0',		'sdmi']	,
['IEN116ns',		'STANDARD',	'5',		'IP',		'1',		'0',		'sdmi']	,
['DNSserv',		'STANDARD',	'6',		'IP',		'1',		'0',		'sdmi']	,
['Logserv',		'STANDARD',	'7',		'IP',		'1',		'0',		'sdmi']	,
['Cookie',		'STANDARD',	'8',		'IP',		'1',		'0',		'sdmi']	,
['Lprserv',		'STANDARD',	'9',		'IP',		'1',		'0',		'sdmi']	,
['Impress',		'STANDARD',	'10',		'IP',		'1',		'0',		'sdmi']	,
['Resource',		'STANDARD',	'11',		'IP',		'1',		'0',		'sdmi']	,
['Hostname',		'STANDARD',	'12',		'ASCII',	'1',		'0',		'si'  ]	,
['Bootsize',		'STANDARD',	'13',		'UNUMBER16',	'1',		'1',		'sdmi']	,
['Dumpfile',		'STANDARD',	'14',		'ASCII',	'1',		'0',		'sdmi']	,
['DNSdmain',		'STANDARD',	'15',		'ASCII',	'1',		'0',		'sdmi']	,
['Swapserv',		'STANDARD',	'16',		'IP',		'1',		'1',		'sdmi']	,
['Rootpath',		'STANDARD',	'17',		'ASCII',	'1',		'0',		'sdmi']	,
['ExtendP',		'STANDARD',	'18',		'ASCII',	'1',		'0',		'sdmi']	,
['IpFwdF',		'STANDARD',	'19',		'UNUMBER8',	'1',		'1',		'sdmi']	,
['NLrouteF',		'STANDARD',	'20',		'UNUMBER8',	'1',		'1',		'sdmi']	,
['PFilter',		'STANDARD',	'21',		'IP',		'2',		'0',		'sdmi']	,
['MaxIpSiz',		'STANDARD',	'22',		'UNUMBER16',	'1',		'1',		'sdmi']	,
['IpTTL',		'STANDARD',	'23',		'UNUMBER8',	'1',		'1',		'sdmi']	,
['PathTO',		'STANDARD',	'24',		'UNUMBER32',	'1',		'1',		'sdmi']	,
['PathTbl',		'STANDARD',	'25',		'UNUMBER16',	'1',		'0',		'sdmi']	,
['MTU',			'STANDARD',	'26',		'UNUMBER16',	'1',		'1',		'sdmi']	,
['SameMtuF',		'STANDARD',	'27',		'UNUMBER8',	'1',		'1',		'sdmi']	,
['Broadcst',		'STANDARD',	'28',		'IP',		'1',		'1',		'sdmi']	,
['MaskDscF',		'STANDARD',	'29',		'UNUMBER8',	'1',		'1',		'sdmi']	,
['MaskSupF',		'STANDARD',	'30',		'UNUMBER8',	'1',		'1',		'sdmi']	,
['RDiscvyF',		'STANDARD',	'31',		'UNUMBER8',	'1',		'1',		'sdmi']	,
['RSolictS',		'STANDARD',	'32',		'IP',		'1',		'1',		'sdmi']	,
['StaticRt',		'STANDARD',	'33',		'IP',		'2',		'0',		'sdmi']	,
['TrailerF',		'STANDARD',	'34',		'UNUMBER8',	'1',		'1',		'sdmi']	,
['ArpTimeO',		'STANDARD',	'35',		'UNUMBER32',	'1',		'1',		'sdmi']	,
['EthEncap',		'STANDARD',	'36',		'UNUMBER8',	'1',		'1',		'sdmi']	,
['TcpTTL',		'STANDARD',	'37',		'UNUMBER8',	'1',		'1',		'sdmi']	,
['TcpKaInt',		'STANDARD',	'38',		'UNUMBER32',	'1',		'1',		'sdmi']	,
['TcpKaGbF',		'STANDARD',	'39',		'UNUMBER8',	'1',		'1',		'sdmi']	,
['NISdmain',		'STANDARD',	'40',		'ASCII',	'1',		'0',		'sdmi']	,
['NISservs',		'STANDARD',	'41',		'IP',		'1',		'0',		'sdmi']	,
['NTPservs',		'STANDARD',	'42',		'IP',		'1',		'0',		'sdmi']	,
['Vendor',		'STANDARD',	'43',		'OCTET',	'1',		'0',		'sdi' ]	,
['NetBNms',		'STANDARD',	'44',		'IP',		'1',		'0',		'sdmi']	,
['NetBDsts',		'STANDARD',	'45',		'IP',		'1',		'0',		'sdmi']	,
['NetBNdT',		'STANDARD',	'46',		'UNUMBER8',	'1',		'1',		'sdmi']	,
['NetBScop',		'STANDARD',	'47',		'ASCII',	'1',		'0',		'sdmi']	,
['XFontSrv',		'STANDARD',	'48',		'IP',		'1',		'0',		'sdmi']	,
['XDispMgr',		'STANDARD',	'49',		'IP',		'1',		'0',		'sdmi']	,
['ReqIP',		'STANDARD',	'50',		'IP',		'1',		'1',		'sdi' ]	,
### ['LeaseTim',		'STANDARD',	'51',		'UNUMBER32',	'1',		'1',		'sdmi']	,
['OptOvrld',		'STANDARD',	'52',		'UNUMBER8',	'1',		'1',		'sdi' ]	,
['DHCPType',		'STANDARD',	'53',		'UNUMBER8',	'1',		'1',		'sdi' ]	,
['ServerID',		'STANDARD',	'54',		'IP',		'1',		'1',		'sdi' ]	,
['ReqList',		'STANDARD',	'55',		'OCTET',	'1',		'0',		'sdi' ]	,
['Message',		'STANDARD',	'56',		'ASCII',	'1',		'0',		'sdi' ]	,
['DHCP_MTU',		'STANDARD',	'57',		'UNUMBER16',	'1',		'1',		'sdi' ]	,
['T1Time',		'STANDARD',	'58',		'UNUMBER32',	'1',		'1',		'sdmi']	,
['T2Time',		'STANDARD',	'59',		'UNUMBER32',	'1',		'1',		'sdmi']	,
['ClassID',		'STANDARD',	'60',		'ASCII',	'1',		'0',		'sdi' ]	,
['ClientID',		'STANDARD',	'61',		'OCTET',	'1',		'0',		'sdi' ]	,
['NW_dmain',		'STANDARD',	'62',		'ASCII',	'1',		'0',		'sdmi']	,
['NWIPOpts',		'STANDARD',	'63',		'OCTET',	'1',		'128',		'sdmi']	,
['NIS+dom',		'STANDARD',	'64',		'ASCII',	'1',		'0',		'sdmi']	,
['NIS+serv',		'STANDARD',	'65',		'IP',		'1',		'0',		'sdmi']	,
['TFTPsrvN',		'STANDARD',	'66',		'ASCII',	'1',		'64',		'sdmi']	,
['OptBootF',		'STANDARD',	'67',		'ASCII',	'1',		'128',		'sdmi']	,
['MblIPAgt',		'STANDARD',	'68',		'IP',		'1',		'0',		'sdmi']	,
['SMTPserv',		'STANDARD',	'69',		'IP',		'1',		'0',		'sdmi']	,
['POP3serv',		'STANDARD',	'70',		'IP',		'1',		'0',		'sdmi']	,
['NNTPserv',		'STANDARD',	'71',		'IP',		'1',		'0',		'sdmi']	,
['WWWservs',		'STANDARD',	'72',		'IP',		'1',		'0',		'sdmi']	,
['Fingersv',		'STANDARD',	'73',		'IP',		'1',		'0',		'sdmi']	,
['IRCservs',		'STANDARD',	'74',		'IP',		'1',		'0',		'sdmi']	,
['STservs',		'STANDARD',	'75',		'IP',		'1',		'0',		'sdmi']	,
['STDAservs',		'STANDARD',	'76',		'IP',		'1',		'0',		'sdmi']	,
['UserClas',		'STANDARD',	'77',		'ASCII',	'1',		'0',		'sdi' ]	,
['SLP_DA',		'STANDARD',	'78',		'OCTET',	'1',		'0',		'sdmi']	,
['SLP_SS',		'STANDARD',	'79',		'OCTET',	'1',		'0',		'sdmi']	,
['AgentOpt',		'STANDARD',	'82',		'OCTET',	'1',		'0',		'sdi' ]	,
['FQDN',		'STANDARD',	'89',		'OCTET',	'1',		'0',		'sdmi']	,
['Opcode',		'FIELD',	'0',		'UNUMBER8',	'1',		'1',		'id'  ]	,
['Htype',		'FIELD',	'1',		'UNUMBER8',	'1',		'1',		'id'  ]	,
['HLen',		'FIELD',	'2',		'UNUMBER8',	'1',		'1',		'id'  ]	,
['Hops',		'FIELD',	'3',		'UNUMBER8',	'1',		'1',		'id'  ]	,
['Xid',			'FIELD',	'4',		'UNUMBER32',	'1',		'1',		'id'  ]	,
['Secs',		'FIELD',	'8',		'UNUMBER16',	'1',		'1',		'id'  ]	,
['Flags',		'FIELD',	'10',		'OCTET',	'1',		'2',		'id'  ]	,
['Ciaddr',		'FIELD',	'12',		'IP',		'1',		'1',		'id'  ]	,
['Yiaddr',		'FIELD',	'16',		'IP',		'1',		'1',		'id'  ]	,
['BootSrvA',		'FIELD',	'20',		'IP',		'1',		'1',		'idm' ]	,
['Giaddr',		'FIELD',	'24',		'IP',		'1',		'1',		'id'  ]	,
['Chaddr',		'FIELD',	'28',		'OCTET',	'1',		'16',		'id'  ]	,
['BootSrvN',		'FIELD',	'44',		'ASCII',	'1',		'64',		'idm' ]	,
['BootFile',		'FIELD',	'108',		'ASCII',	'1',		'128',		'idm' ]	,
['Magic',		'FIELD',	'236',		'OCTET',	'1',		'4',		'id'  ]	,
['Options',		'FIELD',	'240',		'OCTET',	'1',		'60',		'id'  ]	,
### Moved this to a FIELD, it's an INTERNAL thingy in ISC DHCP no 'option' keyword!!! 
['LeaseTim',		'FIELD',	'51',		'UNUMBER32',	'1',		'1',		'sdmi']	,
['Hostname',		'INTERNAL',	'1024',		'BOOL',		'0',		'0',		'dm'  ]	,
['LeaseNeg',		'INTERNAL',	'1025',		'BOOL',		'0',		'0',		'dm'  ]	,
['EchoVC',		'INTERNAL',	'1026',		'BOOL',		'0',		'0',		'dm'  ]	,
['BootPath',		'INTERNAL',	'1027',		'ASCII',	'1',		'128',		'dm'  ]	,
['SrootOpt',		'VENDOR',	'1',		'ASCII',	'1',		'0',		'smi' ]	,
['SrootIP4',		'VENDOR',	'2',		'IP',		'1',		'1',		'smi' ]	,
['SrootNM',		'VENDOR',	'3',		'ASCII',	'1',		'0',		'smi' ]	,
['SrootPTH',		'VENDOR',	'4',		'ASCII',	'1',		'0',		'smi' ]	,
['SswapIP4',		'VENDOR',	'5',		'IP',		'1',		'1',		'smi' ]	,
['SswapPTH',		'VENDOR',	'6',		'ASCII',	'1',		'0',		'smi' ]	,
['SbootFIL',		'VENDOR',	'7',		'ASCII',	'1',		'0',		'smi' ]	,
['Stz',			'VENDOR',	'8',		'ASCII',	'1',		'0',		'smi' ]	,
['SbootRS',		'VENDOR',	'9',		'UNUMBER16',	'1',		'1',		'smi' ]	,
['SinstIP4',		'VENDOR',	'10',		'IP',		'1',		'1',		'smi' ]	,
['SinstNM',		'VENDOR',	'11',		'ASCII',	'1',		'0',		'smi' ]	,
['SinstPTH',		'VENDOR',	'12',		'ASCII',	'1',		'0',		'smi' ]	,
['SsysidCF',		'VENDOR',	'13',		'ASCII',	'1',		'0',		'smi' ]	,
['SjumpsCF',		'VENDOR',	'14',		'ASCII',	'1',		'0',		'smi' ]	,
['Sterm',		'VENDOR',	'15',		'ASCII',	'1',		'0',		'smi' ]	,
['SbootURI',		'VENDOR',	'16',		'ASCII',	'1',		'0',		'smi' ]	,
['SHTTPproxy',		'VENDOR',	'17',		'ASCII',	'1',		'0',		'smi' ] ,
);

$dhcp4_inittab_hash;
foreach my $i (@dhcp4_inittab_array) {
	my ($symbol,$category,$opt_nr,$data_type,$granularity,$max_items,$visibility)=@$i;
	$dhcp4_inittab_hash->{$symbol}->{category}=$category;
	$dhcp4_inittab_hash->{$symbol}->{option_number}=$opt_nr;
	$dhcp4_inittab_hash->{$symbol}->{data_type}=$data_type;
}

# print Dumper ($dhcp4_inittab_hash),"\n";

1;
