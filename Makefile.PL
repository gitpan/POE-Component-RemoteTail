use inc::Module::Install;
name 'POE-Component-RemoteTail';
all_from 'lib/POE/Component/RemoteTail.pm';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
