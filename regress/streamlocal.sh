#	$OpenBSD: forwarding.sh,v 1.20 2017/04/30 23:34:55 djm Exp $
#	Placed in the Public Domain.

tid="streamlocal forwarding"

USER=`id -u`
NC=$OBJ/netcat
REMOTE_DIR=$OBJ/remote-$USER

start_sshd

trace "remote forwarding, relative socket path disabled on server"
rm -f $OBJ/localsock
$NC -U -l $OBJ/localsock > /dev/null &
netcat_pid=$!
${SSH} -F $OBJ/ssh_config -p$PORT -o ExitOnForwardFailure=yes -R ./remotesock:$OBJ/localsock somehost true
r=$?
kill $netcat_pid 2>&1 >/dev/null
if [ $r -eq 0 ]; then
	fail "should fail if relative socket path is disabled"
fi

stop_sshd

start_sshd -o StreamLocalBindRootDirectory=$OBJ/remote-%i

trace "remote forwarding, relative socket path enabled on server, but has wrong permission"
rm -fr $REMOTE_DIR
mkdir $REMOTE_DIR
chmod 0777 $REMOTE_DIR
rm -f $OBJ/localsock
$NC -U -l $OBJ/localsock > /dev/null &
netcat_pid=$!
${SSH} -F $OBJ/ssh_config -p$PORT -o ExitOnForwardFailure=yes -R ./remotesock:$OBJ/localsock somehost true
r=$?
kill $netcat_pid 2>/dev/null
if [ $r -eq 0 ]; then
	fail "should fail if the socket root directory has wrong permission"
fi

trace "remote forwarding, relative socket path enabled on server, and has right permission"
rm -fr $REMOTE_DIR
mkdir $REMOTE_DIR
chmod 0700 $REMOTE_DIR
rm -f $OBJ/localsock
$NC -U -l $OBJ/localsock > /dev/null &
netcat_pid=$!
${SSH} -F $OBJ/ssh_config -p$PORT -o ExitOnForwardFailure=yes -R ./remotesock:$OBJ/localsock somehost true
r=$?
kill $netcat_pid 2>/dev/null
if [ $r -ne 0 ]; then
	fail "should succeed if the socket root directory has right permission"
fi

stop_sshd

rm -f $OBJ/localsock
rm -f $OBJ/remotesock
rm -fr $REMOTE_DIR
