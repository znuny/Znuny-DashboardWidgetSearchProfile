# --
# Copyright (C) 2012-2021 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

# get needed objects
my $GroupObject         = $Kernel::OM->Get('Kernel::System::Group');
my $HelperObject        = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $SearchProfileObject = $Kernel::OM->Get('Kernel::System::SearchProfile');
my $UnitTestParamObject = $Kernel::OM->Get('Kernel::System::UnitTest::Param');
my $ZnunyHelperObject   = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

#
# create 2 test users which will have a grouped search profile
#

my %UserData1 = $HelperObject->TestUserDataGet(
    Groups   => [ 'admin', 'users' ],
    Language => 'de'
);
my %UserData2 = $HelperObject->TestUserDataGet(
    Groups   => [ 'admin', 'users' ],
    Language => 'de'
);

#
# create standard local search profile for user 2
#

my $SearchProfileAdd = $SearchProfileObject->SearchProfileAdd(
    Base      => 'TicketSearch',
    Name      => 'blub',
    Key       => 'Local',
    Value     => '123',
    UserLogin => $UserData2{UserLogin},
);

$Self->True(
    $SearchProfileAdd,
    'Added key for search profile "blub"',
);

#
# prepare params to simulate grouped search profile add
#

$UnitTestParamObject->ParamSet(
    Name  => 'SaveProfile',
    Value => 1,
);
$UnitTestParamObject->ParamSet(
    Name  => 'Profile',
    Value => 'blub',
);
$UnitTestParamObject->ParamSet(
    Name  => 'Znuny4OTRSSaveDashboard',
    Value => 1,
);
$UnitTestParamObject->ParamSet(
    Name  => 'Znuny4OTRSSaveGroups',
    Value => [
        $GroupObject->GroupLookup( Group => 'admin' ),
        $GroupObject->GroupLookup( Group => 'users' ),
    ],
);

#
# add test data to the example grouped search profile
#

$SearchProfileAdd = $SearchProfileObject->SearchProfileAdd(
    Base      => 'TicketSearch',
    Name      => 'blub',
    Key       => 'Body',
    Value     => '123',
    UserLogin => $UserData1{UserLogin},
);

$Self->True(
    $SearchProfileAdd,
    'Added key for search profile "blub" for user 1 which will be grouped',
);

$SearchProfileAdd = $SearchProfileObject->SearchProfileAdd(
    Base      => 'TicketSearch',
    Name      => 'blub',
    Key       => 'Subject',
    Value     => '123',
    UserLogin => $UserData1{UserLogin},
);

$Self->True(
    $SearchProfileAdd,
    'Added key for search profile "blub" for user 1 which will be grouped',
);

#
# verify grouped profile data with user 1
#

my %SearchProfileData = $SearchProfileObject->SearchProfileGet(
    Base      => 'TicketSearch',
    Name      => 'blub',
    UserLogin => $UserData1{UserLogin},
);

$Self->Is(
    $SearchProfileData{Body},
    '123',
    'search profile contains the correct body value',
);
$Self->Is(
    $SearchProfileData{Subject},
    '123',
    'search profile contains the correct subject value',
);
$Self->Is(
    $SearchProfileData{Znuny4OTRSSaveDashboard},
    '1',
    'search profile contains the correct dashboard value',
);

my @Data1 = sort @{ $SearchProfileData{Znuny4OTRSSaveGroups} };
my @Data2 = sort( (
        $GroupObject->GroupLookup( Group => 'admin' ),
        $GroupObject->GroupLookup( Group => 'users' ),
) );

my $GroupsDifferent = DataIsDifferent(
    Data1 => \@Data1,
    Data2 => \@Data2,
);
$Self->False(
    $GroupsDifferent,
    'search profile contains the correct list of groups',
);

#
# verify grouped profile data with user 2
#

%SearchProfileData = $SearchProfileObject->SearchProfileGet(
    Base      => 'TicketSearch',
    Name      => 'blub',
    UserLogin => $UserData2{UserLogin},
);

$Self->Is(
    $SearchProfileData{Body},
    '123',
    'search profile contains the correct body value',
);
$Self->Is(
    $SearchProfileData{Subject},
    '123',
    'search profile contains the correct subject value',
);
$Self->Is(
    $SearchProfileData{Znuny4OTRSSaveDashboard},
    '1',
    'search profile contains the correct dashboard value',
);

@Data1 = sort @{ $SearchProfileData{Znuny4OTRSSaveGroups} };
@Data2 = sort( (
        $GroupObject->GroupLookup( Group => 'admin' ),
        $GroupObject->GroupLookup( Group => 'users' ),
) );

$GroupsDifferent = DataIsDifferent(
    Data1 => \@Data1,
    Data2 => \@Data2,
);
$Self->False(
    $GroupsDifferent,
    'search profile contains the correct list of groups',
);

#
# check values of list function for both users
#

# user 1
my %SearchProfileListUserData1 = $SearchProfileObject->SearchProfileList(
    Base      => 'TicketSearch',
    UserLogin => $UserData1{UserLogin},
);
$Self->True(
    $SearchProfileListUserData1{blub},
    'grouped search profile is listed for user 1',
);

# user 2
my %SearchProfileListUserData2 = $SearchProfileObject->SearchProfileList(
    Base      => 'TicketSearch',
    UserLogin => $UserData2{UserLogin},
);
$Self->True(
    $SearchProfileListUserData2{blub},
    'grouped search profile is listed for user 2',
);

#
# now we change some values for the profile with user 2 (which got permissions over groups)
#

my $SearchProfileDelete = $SearchProfileObject->SearchProfileDelete(
    Base      => 'TicketSearch',
    Name      => 'blub',
    UserLogin => $UserData2{UserLogin},
    ,
);

$Self->True(
    $SearchProfileDelete,
    'remove all values for the grouped user but with user 2 which is not the "technical" owner of the search profile',
);

$SearchProfileAdd = $SearchProfileObject->SearchProfileAdd(
    Base      => 'TicketSearch',
    Name      => 'blub',
    Key       => 'Body',
    Value     => '234',
    UserLogin => $UserData2{UserLogin},
);

$Self->True(
    $SearchProfileAdd,
    'Added key for search profile "blub"',
);

$SearchProfileAdd = $SearchProfileObject->SearchProfileAdd(
    Base      => 'TicketSearch',
    Name      => 'blub',
    Key       => 'Subject',
    Value     => '234',
    UserLogin => $UserData2{UserLogin},
);

$Self->True(
    $SearchProfileAdd,
    'Added key for search profile "blub"',
);

#
# verify grouped profile data with user 1
#

%SearchProfileData = $SearchProfileObject->SearchProfileGet(
    Base      => 'TicketSearch',
    Name      => 'blub',
    UserLogin => $UserData1{UserLogin},
);

$Self->Is(
    $SearchProfileData{Body},
    '234',
    'search profile contains the correct body value',
);
$Self->Is(
    $SearchProfileData{Subject},
    '234',
    'search profile contains the correct subject value',
);
$Self->Is(
    $SearchProfileData{Local},
    undef,
    'search profile contains the correct subject value',
);
$Self->Is(
    $SearchProfileData{Znuny4OTRSSaveDashboard},
    '1',
    'search profile contains the correct dashboard value',
);

@Data1 = sort @{ $SearchProfileData{Znuny4OTRSSaveGroups} };
@Data2 = sort( (
        $GroupObject->GroupLookup( Group => 'admin' ),
        $GroupObject->GroupLookup( Group => 'users' ),
) );

$GroupsDifferent = DataIsDifferent(
    Data1 => \@Data1,
    Data2 => \@Data2,
);
$Self->False(
    $GroupsDifferent,
    'search profile contains the correct list of groups',
);

#
# verify grouped profile data with user 2
#

%SearchProfileData = $SearchProfileObject->SearchProfileGet(
    Base      => 'TicketSearch',
    Name      => 'blub',
    UserLogin => $UserData2{UserLogin},
);

$Self->Is(
    $SearchProfileData{Body},
    '234',
    'search profile contains the correct body value',
);
$Self->Is(
    $SearchProfileData{Subject},
    '234',
    'search profile contains the correct subject value',
);
$Self->Is(
    $SearchProfileData{Znuny4OTRSSaveDashboard},
    '1',
    'search profile contains the correct dashboard value',
);

@Data1 = sort @{ $SearchProfileData{Znuny4OTRSSaveGroups} };
@Data2 = sort( (
        $GroupObject->GroupLookup( Group => 'admin' ),
        $GroupObject->GroupLookup( Group => 'users' ),
) );

$GroupsDifferent = DataIsDifferent(
    Data1 => \@Data1,
    Data2 => \@Data2,
);
$Self->False(
    $GroupsDifferent,
    'search profile contains the correct list of groups',
);

1;
