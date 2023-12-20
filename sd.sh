#!/bin/bash
slow_file='/etc/slowDNS'
slow_bin="$slow_file/bin"
export PATH=$PATH:$slow_bin

repo_install(){
  link="https://raw.githubusercontent.com/rudi9999/ADMRufu/main/Repositorios/$VERSION_ID.list"
  case $VERSION_ID in
    8*|9*|10*|11*|16.04*|18.04*|20.04*|20.10*|21.04*|21.10*|22.04*) [[ ! -e /etc/apt/sources.list.back ]] && cp /etc/apt/sources.list /etc/apt/sources.list.back
                                                                    wget -O /etc/apt/sources.list ${link} &>/dev/null;;
  esac
}

time_reboot(){
  print_center -ama "REINICIANDO VPS EN $1 SEGUNDOS"
  REBOOT_TIMEOUT="$1"
  
  while [ $REBOOT_TIMEOUT -gt 0 ]; do
     print_center -ne "-$REBOOT_TIMEOUT-\r"
     sleep 1
     : $((REBOOT_TIMEOUT--))
  done
  reboot
}

check_sistem(){
  fail(){
    clear
    echo -e "\e[1m\e[31m=====================================================\e[0m"
    echo -e "\e[1m\e[33mthis script is not compatible with your operating system\e[0m"
    echo -e "\e[1m\e[33m              Use Ubuntu 18 or higher\e[0m"
    echo -e "\e[1m\e[31m=====================================================\e[0m"
    exit
  }
  VER=$(echo $VERSION_ID|awk -F '.' '{print $1}')
  if [[ ! $NAME = 'Ubuntu' ]]; then
    fail
  elif [[ $VER -lt 18 ]]; then
      fail
  fi
}

if [[ ! -e $slow_file/SlowDNS.sh ]]; then
  source /etc/os-release
  check_sistem
	[[ ! -d $slow_file ]] && mkdir $slow_file
	chmod -R +x $slow_file
	wget -O $slow_file/module 'https://raw.githubusercontent.com/rudi9999/Herramientas/main/module/module' &>/dev/null
	chmod +x $slow_file/module
	source $slow_file/module
	wget -O $slow_file/limitador.sh "https://raw.githubusercontent.com/rudi9999/SocksIP-udpServer/main/limitador.sh" &>/dev/null
	chmod +x $slow_file/limitador.sh
	echo "$slow_file/SlowDNS.sh" > /usr/bin/slowdns
	chmod +x /usr/bin/slowdns
	repo_install
	#apt update -y && apt upgrade -y
	ufw disable
	apt remove netfilter-persistent -y
	cp $(pwd)/$0 $slow_file/SlowDNS.sh
	chmod +x $slow_file/SlowDNS.sh
	rm $(pwd)/$0 &> /dev/null
	title 'INSTALLATION COMPLETE'
	print_center -ama "use the command\nslowdns\nto run the menu"
	msg -bar
	time_reboot 10
fi

newlang='en_US'
source $slow_file/module

ip_publica=$(grep -m 1 -oE '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' <<< "$(wget -T 10 -t 1 -4qO- "http://ip1.dynupdate.no-ip.com/" || curl -m 10 -4Ls "http://ip1.dynupdate.no-ip.com/")")

#======= CONFIGURACION CUENTAS SSH =======

data_user(){
	cat_users=$(cat "/etc/passwd"|grep 'home'|grep 'false'|grep -v 'syslog'|grep -v '::/'|grep -v 'hwid\|token')
	[[ -z "$(echo "${cat_users}"|head -1)" ]] && print_center -verm2 "NO REGISTERED SSH USERS" && return 1
  #dat_us=$(printf '%-13s%-14s%-10s%-4s%-6s%s' 'Usuario' 'Contraseña' 'Fecha' 'Dia' 'Limit' 'Statu')
	dat_us=$(printf '%-13s%-14s%-10s%-4s%-6s%s' 'User' 'Password' 'Date' 'Day' 'Limit' 'Status')
	msg -azu "  $dat_us"
	msg -bar

	i=1

  while read line; do
    u=$(echo "$line"|awk -F ':' '{print $1}')

    fecha=$(chage -l "$u"|sed -n '4p'|awk -F ': ' '{print $2}')

    mes_dia=$(echo $fecha|awk -F ',' '{print $1}'|sed 's/ //g')
    ano=$(echo $fecha|awk -F ', ' '{printf $2}'|cut -c 3-)
    us=$(printf '%-12s' "$u")

    pass=$(echo "$line"|awk -F ':' '{print $5}'|cut -d ',' -f2)
    [[ "${#pass}" -gt '12' ]] && pass="unknown"
    pass="$(printf '%-12s' "$pass")"

    unset stat
    if [[ $(passwd --status $u|cut -d ' ' -f2) = "P" ]]; then
      stat="$(msg -verd "ULK")"
    else
      stat="$(msg -verm2 "LOK")"
    fi

    Limit=$(echo "$line"|awk -F ':' '{print $5}'|cut -d ',' -f1)
    [[ "${#Limit}" = "1" ]] && Limit=$(printf '%2s%-4s' "$Limit") || Limit=$(printf '%-6s' "$Limit")

    echo -ne "$(msg -verd "$i")$(msg -verm2 "-")$(msg -azu "${us}") $(msg -azu "${pass}")"
    if [[ $(echo $fecha|awk '{print $2}') = "" ]]; then
      exp="$(printf '%8s%-2s' '[X]')"
      exp+="$(printf '%-6s' '[X]')"
      echo " $(msg -verm2 "$fecha")$(msg -verd "$exp")$(echo -e "$stat")" 
    else
      if [[ $(date +%s) -gt $(date '+%s' -d "${fecha}") ]]; then
        exp="$(printf '%-5s' "Exp")"
        echo " $(msg -verm2 "$mes_dia/$ano")  $(msg -verm2 "$exp")$(msg -ama "$Limit")$(echo -e "$stat")"
      else
        EXPTIME="$(($(($(date '+%s' -d "${fecha}") - $(date +%s))) / 86400))"
        [[ "${#EXPTIME}" = "1" ]] && exp="$(printf '%2s%-3s' "$EXPTIME")" || exp="$(printf '%-5s' "$EXPTIME")"
        echo " $(msg -verm2 "$mes_dia/$ano")  $(msg -verd "$exp")$(msg -ama "$Limit")$(echo -e "$stat")"
      fi
    fi
    let i++
  done <<< "$cat_users"
}

mostrar_usuarios(){
  for u in `cat /etc/passwd|grep 'home'|grep 'false'|grep -v 'syslog'|grep -v 'hwid'|grep -v 'token'|grep -v '::/'|awk -F ':' '{print $1}'`; do
    echo "$u"
  done
}
#======= limitadr multi-login =====

limiter(){

	ltr(){
		clear
		msg -bar
		for i in `atq|awk '{print $1}'`; do
			if [[ ! $(at -c $i|grep 'limitador.sh') = "" ]]; then
				atrm $i
				sed -i '/limitador.sh/d' /var/spool/cron/crontabs/root
				print_center -verd "limiter stopped"
				enter
				return
			fi
		done
    print_center -ama "CONF LIMITER"
    msg -bar
    print_center -ama "Block users when they exceed"
    print_center -ama "the maximum number of connections"
    msg -bar
    unset opcion
    while [[ -z $opcion ]]; do
      msg -nama " run limiter every: "
      read opcion
      if [[ ! $opcion =~ $numero ]]; then
        del 1
        print_center -verm2 " Only numbers are allowed"
        sleep 2
        del 1
        unset opcion && continue
      elif [[ $opcion -le 0 ]]; then
        del 1
        print_center -verm2 "minimum time 1 minute"
        sleep 2
        del 1
        unset opcion && continue
      fi
      del 1
      echo -e "$(msg -nama " Run limitor every:") $(msg -verd "$opcion minutes")"
      echo "$opcion" > $slow_file/limit
    done

    msg -bar
    print_center -ama "Users blocked by limiter\nthey will be unlocked automatically\n(enter 0 for manual unlock)"
    msg -bar

    unset opcion
    while [[ -z $opcion ]]; do
      msg -nama " Unlock user every: "
      read opcion
      if [[ ! $opcion =~ $numero ]]; then
        tput cuu1 && tput dl1
        print_center -verm2 " Only numbers are allowed"
        sleep 2
        tput cuu1 && tput dl1
        unset opcion && continue
      fi
      tput cuu1 && tput dl1
      [[ $opcion -le 0 ]] && echo -e "$(msg -nama " unlock:") $(msg -verd "manual")" || echo -e "$(msg -nama " Unlock user every:") $(msg -verd "$opcion minutes")"
      echo "$opcion" > $slow_file/unlimit
    done
		nohup $slow_file/limitador.sh &>/dev/null &
    msg -bar
		print_center -verd "running limiter"
		enter	
	}

	l_exp(){
		clear
    	msg -bar
    	l_cron=$(cat /var/spool/cron/crontabs/root|grep -w 'limitador.sh'|grep -w 'ssh')
    	if [[ -z "$l_cron" ]]; then
      		echo '0 1 * * * /etc/UDPserver/limitador.sh --ssh' >> /var/spool/cron/crontabs/root
      		print_center -verd "programmed expire limiter\nIt will run every day at 1:00 a.m.\naccording to the time scheduled on the server"
      		enter
      		return
    	else
      		sed -i '/limitador.sh --ssh/d' /var/spool/cron/crontabs/root
      		print_center -verm2 "expired limiter stopped" 
      		enter
      		return   
    	fi
	}

	log(){
		clear
		msg -bar
		print_center -ama "LIMITER REGISTRATION"
		msg -bar
		[[ ! -e $slow_file/limit.log ]] && touch $slow_file/limit.log
		if [[ -z $(cat $slow_file/limit.log) ]]; then
			print_center -ama "no register limiter"
			msg -bar
			sleep 2
			return
		fi
		msg -teal "$(cat $slow_file/limit.log)"
		msg -bar
		print_center -ama "►► Press enter to continue or ◄◄"
		print_center -ama "►► 0 to clear record ◄◄"
		read opcion
		[[ $opcion = "0" ]] && echo "" > $slow_file/limit.log
	}

	[[ $(cat /var/spool/cron/crontabs/root|grep -w 'limitador.sh'|grep -w 'ssh') ]] && lim_e=$(msg -verd "[ON]") || lim_e=$(msg -verm2 "[OFF]")

	clear
	msg -bar
	print_center -ama "ACCOUNT LIMITER"
	msg -bar
	menu_func "MULTI-LOGIN LIMITER" "EXPIRED LIMITER $lim_e" "LIMITER LOG"
	back
	msg -ne " option: "
	read opcion
	case $opcion in
		1)ltr;;
		2)l_exp;;
		3)log;;
		0)return;;
	esac
}

# ======== detalles de clientes ====

detail_user(){
	clear
	usuarios_ativos=('' $(mostrar_usuarios))
	if [[ -z ${usuarios_ativos[@]} ]]; then
		msg -bar
		print_center -verm2 "No registered user"
		msg -bar
		sleep 3
		return
	else
		msg -bar
		print_center -ama "DETAILS OF THE USERS"
		msg -bar
	fi
	data_user
	msg -bar
	enter
}

#======== bloquear clientes ======

block_user(){
  clear
  usuarios_ativos=('' $(mostrar_usuarios))
  msg -bar
  print_center -ama "LOCK/UNLOCK USERS"
  msg -bar
  data_user
  back

  print_center -ama "Write or Select a User"
  msg -bar
  unset selection
  while [[ ${selection} = "" ]]; do
    echo -ne "\033[1;37m Select: " && read selection
    del 1
  done
  [[ ${selection} = "0" ]] && return
  if [[ ! $(echo "${selection}" | egrep '[^0-9]') ]]; then
    usuario_del="${usuarios_ativos[$selection]}"
  else
    usuario_del="$selection"
  fi
  [[ -z $usuario_del ]] && {
    msg -verm "Error, Invalid User"
    msg -bar
    return 1
  }
  [[ ! $(echo ${usuarios_ativos[@]}|grep -w "$usuario_del") ]] && {
    msg -verm "Error, Invalid User"
    msg -bar
    return 1
  }

  msg -nama "   $(fun_trans "User"): $usuario_del >>>> "

  if [[ $(passwd --status $usuario_del|cut -d ' ' -f2) = "P" ]]; then
    pkill -u $usuario_del &>/dev/null
    droplim=`droppids|grep -w "$usuario_del"|awk '{print $2}'` 
    kill -9 $droplim &>/dev/null
    usermod -L $usuario_del &>/dev/null
    sleep 2
    msg -verm2 "locked"
  else
  	usermod -U $usuario_del
  	sleep 2
  	msg -verd "unlocked"
  fi
  msg -bar
  sleep 3
}

#========renovar cliente =========

renew_user_fun(){
  #nome dias
  datexp=$(date "+%F" -d " + $2 days") && valid=$(date '+%C%y-%m-%d' -d " + $2 days")
  if chage -E $valid $1 ; then
  	print_center -ama "Successfully Renewed User"
  else
  	print_center -verm "Error, User not Renewed"
  fi
}

renew_user(){
  clear
  usuarios_ativos=('' $(mostrar_usuarios))
  msg -bar
  print_center -ama "RENEW USERS"
  msg -bar
  data_user
  back

  print_center -ama "Write or select a User"
  msg -bar
  unset selection
  while [[ -z ${selection} ]]; do
    msg -nazu "Select an Option: " && read selection
    del 1
  done

  [[ ${selection} = "0" ]] && return
  if [[ ! $(echo "${selection}" | egrep '[^0-9]') ]]; then
    useredit="${usuarios_ativos[$selection]}"
  else
    useredit="$selection"
  fi

  [[ -z $useredit ]] && {
    msg -verm "Error, Invalid User"
    msg -bar
    sleep 3
    return 1
  }

  [[ ! $(echo ${usuarios_ativos[@]}|grep -w "$useredit") ]] && {
    msg -verm "Error, Invalid User"
    msg -bar
    sleep 3
    return 1
  }

  while true; do
    msg -ne "New Duration Time: $useredit"
    read -p ": " diasuser
    if [[ -z "$diasuser" ]]; then
      echo -e '\n\n\n'
      err_fun 7 && continue
    elif [[ "$diasuser" != +([0-9]) ]]; then
      echo -e '\n\n\n'
      err_fun 8 && continue
    elif [[ "$diasuser" -gt "360" ]]; then
      echo -e '\n\n\n'
      err_fun 9 && continue
    fi
    break
  done
  msg -bar
  renew_user_fun "${useredit}" "${diasuser}"
  msg -bar
  sleep 3
}

#======== remover cliente =========

droppids(){
  port_dropbear=`ps aux|grep 'dropbear'|awk NR==1|awk '{print $17;}'`
  log=/var/log/auth.log
  loginsukses='Password auth succeeded'
  pids=`ps ax|grep 'dropbear'|grep " $port_dropbear"|awk -F " " '{print $1}'`
  for pid in $pids; do
    pidlogs=`grep $pid $log |grep "$loginsukses" |awk -F" " '{print $3}'`
    i=0
    for pidend in $pidlogs; do
      let i=i+1
    done
    if [ $pidend ];then
       login=`grep $pid $log |grep "$pidend" |grep "$loginsukses"`
       PID=$pid
       user=`echo $login |awk -F" " '{print $10}' | sed -r "s/'/ /g"`
       waktu=`echo $login |awk -F" " '{print $2"-"$1,$3}'`
       while [ ${#waktu} -lt 13 ]; do
           waktu=$waktu" "
       done
       while [ ${#user} -lt 16 ]; do
           user=$user" "
       done
       while [ ${#PID} -lt 8 ]; do
           PID=$PID" "
       done
       echo "$user $PID $waktu"
    fi
	done
}

rm_user(){
  pkill -u $1
  droplim=`droppids|grep -w "$1"|awk '{print $2}'` 
  kill -9 $droplim &>/dev/null
  userdel --force "$1" &>/dev/null
  msj=$?
}

remove_user(){
	clear
	usuarios_ativos=('' $(mostrar_usuarios))
	msg -bar
	print_center -ama "REMOVE USERS"
	msg -bar
	data_user
	back

	print_center -ama "Write or Select a User"
	msg -bar
	unset selection
	while [[ -z ${selection} ]]; do
		msg -nazu "Select An Option: " && read selection
		tput cuu1 && tput dl1
	done
	[[ ${selection} = "0" ]] && return
	if [[ ! $(echo "${selection}" | egrep '[^0-9]') ]]; then
		usuario_del="${usuarios_ativos[$selection]}"
	else
		usuario_del="$selection"
	fi
	[[ -z $usuario_del ]] && {
		msg -verm "Error, Invalid User"
		msg -bar
		return 1
	}
	[[ ! $(echo ${usuarios_ativos[@]}|grep -w "$usuario_del") ]] && {
		msg -verm "Error, Invalid Usero"
		msg -bar
		return 1
	}

	print_center -ama "Selected User: $usuario_del"
	rm_user "$usuario_del"
  if [[ $msj = 0 ]] ; then
    print_center -verd "[removed]"
  else
    print_center -verm "[not removed]"
  fi
  enter
}

#========crear cliente =============
add_user(){
  Fecha=`date +%d-%m-%y-%R`
  [[ $(cat /etc/passwd |grep $1: |grep -vi [a-z]$1 |grep -v [0-9]$1 > /dev/null) ]] && return 1
  valid=$(date '+%C%y-%m-%d' -d " +$3 days")
  osl_v=$(openssl version|awk '{print $2}')
  osl_v=${osl_v:0:5}
  if [[ $osl_v = '1.1.1' ]]; then
    pass=$(openssl passwd -6 $2)
  else
    pass=$(openssl passwd -1 $2)
  fi
  useradd -M -s /bin/false -e ${valid} -K PASS_MAX_DAYS=$3 -p ${pass} -c $4,$2 $1 &>/dev/null
  msj=$?
}

new_user(){
  clear
  usuarios_ativos=('' $(mostrar_usuarios))
  msg -bar
  print_center -ama "CREATE CUSTOMER"
  msg -bar
  data_user
  back

  while true; do
    msg -ne " Username: "
    read nomeuser
    nomeuser="$(echo $nomeuser|sed 'y/áÁàÀãÃâÂéÉêÊíÍóÓõÕôÔúÚñÑçÇªº/aAaAaAaAeEeEiIoOoOoOuUnNcCao/')"
    nomeuser="$(echo $nomeuser|sed -e 's/[^a-z0-9 -]//ig')"
    if [[ -z $nomeuser ]]; then
      err_fun 1 && continue
    elif [[ "${nomeuser}" = "0" ]]; then
      return
    elif [[ "${#nomeuser}" -lt "4" ]]; then
      err_fun 2 && continue
    elif [[ "${#nomeuser}" -gt "12" ]]; then
      err_fun 3 && continue
    elif [[ "$(echo ${usuarios_ativos[@]}|grep -w "$nomeuser")" ]]; then
      err_fun 14 && continue
    fi
    break
  done

  while true; do
    msg -ne " User Password"
    read -p ": " senhauser
    senhauser="$(echo $senhauser|sed 'y/áÁàÀãÃâÂéÉêÊíÍóÓõÕôÔúÚñÑçÇªº/aAaAaAaAeEeEiIoOoOoOuUnNcCao/')"
    if [[ -z $senhauser ]]; then
      err_fun 4 && continue
    elif [[ "${#senhauser}" -lt "4" ]]; then
      err_fun 5 && continue
    elif [[ "${#senhauser}" -gt "12" ]]; then
      err_fun 6 && continue
    fi
    break
  done

  while true; do
    msg -ne " Duration time"
    read -p ": " diasuser
    if [[ -z "$diasuser" ]]; then
      err_fun 7 && continue
    elif [[ "$diasuser" != +([0-9]) ]]; then
      err_fun 8 && continue
    elif [[ "$diasuser" -gt "360" ]]; then
      err_fun 9 && continue
    fi 
    break
  done

  while true; do
    msg -ne " Connection Limit"
    read -p ": " limiteuser
    if [[ -z "$limiteuser" ]]; then
      err_fun 11 && continue
    elif [[ "$limiteuser" != +([0-9]) ]]; then
      err_fun 12 && continue
    elif [[ "$limiteuser" -gt "999" ]]; then
      err_fun 13 && continue
    fi
    break
  done

  add_user "${nomeuser}" "${senhauser}" "${diasuser}" "${limiteuser}"
  clear
  msg -bar
  if [[ $msj = 0 ]]; then
    print_center -verd "User Created Successfully"
  else
    print_center -verm2 "Error, User not created"
    enter
    return 1
  fi
  msg -bar
  msg -ne " Server IP: " && msg -ama "    $ip_publica"
  msg -ne " User: " && msg -ama "            $nomeuser"
  msg -ne " Password: " && msg -ama "         $senhauser"
  msg -ne " Duration days: " && msg -ama "   $diasuser"
  msg -ne " Connection Limit: " && msg -ama " $limiteuser"
  msg -ne " Expiration date: " && msg -ama "$(date "+%F" -d " + $diasuser days")"
  enter
}

#=======================================
#======= CONFIGURACION UDPSERVER ========

download_slowdns(){
  [[ ! -d $slow_bin ]] && mkdir $slow_bin
	msg -nama '        Downloading slowDNS binary .....'
	if wget -O $slow_bin/dns-server 'https://github.com/rudi9999/ADMRufu/raw/main/Utils/SlowDNS/dns-server' &>/dev/null ; then
		chmod +x $slow_bin/dns-server
    [[ $ex_key = @(n|N) ]] && dns-server -gen-key -privkey-file $slow_file/server.key -pubkey-file $slow_file/server.pub &>/dev/null
		msg -verd 'OK'
	else
		msg -verm2 'fail'
		rm -rf $slow_bin/dns-server*
	fi
}

make_service(){
	#ip_nat=$(ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | sed -n 1p)
	#interfas=$(ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}'|grep "$ip_nat"|awk {'print $NF'})
	#ip_publica=$(grep -m 1 -oE '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' <<< "$(wget -T 10 -t 1 -4qO- "http://ip1.dynupdate.no-ip.com/" || curl -m 10 -4Ls "http://ip1.dynupdate.no-ip.com/")")

  iptables_path=$(command -v iptables)
  slow_b=$(type -p dns-server)

cat <<EOF > /etc/systemd/system/slowdns-iptables.service
[Unit]
Before=network.target

[Service]
Type=oneshot

ExecStart=$iptables_path -I INPUT -p udp --dport 5300 -j ACCEPT
ExecStart=$iptables_path -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
ExecStop=$iptables_path -D INPUT -p udp --dport 5300 -j ACCEPT
ExecStop=$iptables_path -t nat -D PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF > /etc/systemd/system/slowdns.service
[Unit]
Description=DNSTT Service by @Rufu99
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=root
WorkingDirectory=/root
ExecStart=$slow_b -udp :5300 -privkey-file $slow_file/server.key $NS 127.0.0.1:$PORT
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

	msg -nama '        Running slowDNS service.....'
	
  systemctl start slowdns-iptables &>/dev/null
  systemctl start slowdns &>/dev/null

	if [[ $(systemctl is-active slowdns) = 'active' ]]; then
		msg -verd 'OK'
		systemctl enable slowdns &>/dev/null
    systemctl enable slowdns-iptables &>/dev/null
	else
		msg -verm2 'fail'
    systemctl stop slowdns-iptables &>/dev/null
    systemctl disable slowdns-iptables &>/dev/null
    systemctl stop slowdns &>/dev/null
    rm -rf /etc/systemd/system/slowdns.service
    rm -rf /etc/systemd/system/slowdns-iptables.service
    rm -rf $slow_file/dns-server*
	fi
}

drop_port(){
    local portasVAR=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND" | grep "LISTEN")
    local NOREPEAT
    local reQ
    local Port
    unset DPB
    while read port; do
        reQ=$(echo ${port}|awk '{print $1}')
        Port=$(echo {$port} | awk '{print $9}' | awk -F ":" '{print $2}')
        [[ $(echo -e $NOREPEAT|grep -w "$Port") ]] && continue
        NOREPEAT+="$Port\n"

        case ${reQ} in
          sshd|dropbear|stunnel4|stunnel|python|python3)DPB+=" $reQ:$Port";;
            *)continue;;
        esac
    done <<< "${portasVAR}"
 }

make_data(){
  drop_port
  n=0
  for i in $DPB; do
    let n++
    proto=$(echo $i|awk -F ":" '{print $1}')
    proto2=$(printf '%-12s' "$proto")
    port=$(echo $i|awk -F ":" '{print $2}')
    echo -e " $(msg -verd "[$n]") $(msg -verm2 ">") $(msg -ama "$proto2")$(msg -azu "$port")"
    drop[$n]=$port ; num_opc="$n"   
  done
  msg -bar
  opc=$(selection_fun $num_opc)
  del $(($n + 1))
  echo "${drop[$opc]}" > $slow_file/puerto
  PORT=$(cat $slow_file/puerto)
  echo " $(msg -ama "Connection port through SlowDNS:") $(msg -verd "$PORT")"
  msg -bar3
  unset NS
  while [[ -z $NS ]]; do
    msg -nama " Your NS domain: "
    read NS
    del 1
  done
  echo "$NS" > $slow_file/domain_ns
  echo " $(msg -ama "YOUR NS DOMAIN:") $(msg -verd "$NS")"

  if [[ -e "$slow_file/server.pub" ]]; then
      pub=$(cat $slow_file/server.pub)
      [[ ! -z $pub ]] && msg -bar3
  else
      ex_key='n'
  fi

  while [[ ! -z $pub ]] && [[ -z $ex_key ]]; do
      read -rp " $(msg -ama "USE EXISTING KEY? [Y/N]:") " -e -i S ex_key
      del 1
      if [[ -z $ex_key ]]; then
          print_center -verm2 'ENTER A VALUE [Y] O [N]'
          sleep 2
          del 1
          unset ex_key
      elif [[ $ex_key != @(y|Y|s|S|n|N) ]]; then
          print_center -verm2 'ENTER A VALUE [Y] O [N]'
          sleep 2
          del 1
          unset ex_key
      fi
  done

  case $ex_key in
      s|S|y|Y) echo " $(msg -ama "YOUR KEY:") $(msg -verd "$(cat $slow_file/server.pub)")";;
          n|N) rm -rf $slow_file/server.key; rm -rf $slow_file/server.pub ; [[ ! -z $pub ]] && del 1
  esac
  msg -bar
}

install_slow(){
	title 'slowDNS INSTALLATION'
  make_data
	download_slowdns
	if [[ $(type -p dns-server) ]]; then
		make_service
		msg -bar3
		if [[ $(systemctl is-active slowdns) = 'active' ]]; then
			print_center -verd 'installation complete'
		else
			print_center -verm2 'fail to run service'
		fi
	else
		echo
		print_center -ama 'Failed to download slowdns binary'
	fi
	enter	
}

uninstall_slow(){
	title 'UNINSTALLER slowDNS'
	read -rp " $(msg -ama "WANT TO UNINSTALL slowDNS [Y/N]?:") " -e -i Y UNINS
	[[ $UNINS != @(Y|y) ]] && return
  systemctl stop slowdns &>/dev/null
	systemctl stop slowdns-iptables &>/dev/null

  systemctl disable slowdns &>/dev/null
	systemctl disable slowdns-iptables &>/dev/null

  rm -rf /etc/systemd/system/slowdns.service
	rm -rf /etc/systemd/system/slowdns-iptables.service
	rm -rf $(type -p dns-server)
  rm $slow_file/domain_ns
  rm $slow_file/puerto
  rm $slow_file/server.pub
  rm $slow_file/server.key
	del 1
	print_center -ama "complete uninstall!"
	enter
}

reset(){
	if [[ $(systemctl is-active slowdns) = 'active' ]]; then
    systemctl stop slowdns &>/dev/null
		systemctl stop slowdns-iptables &>/dev/null
    systemctl disable slowdns &>/dev/null
		systemctl disable slowdns-iptables &>/dev/null
		print_center -ama 'slowDNS stopped!'
	else
    systemctl start slowdns-iptables &>/dev/null
		systemctl start slowdns &>/dev/null
		if [[ $(systemctl is-active slowdns) = 'active' ]]; then
      systemctl enable slowdns &>/dev/null
			systemctl enable slowdns-iptables &>/dev/null
			print_center -verd 'slowDNS started!'
		else
      systemctl stop slowdns &>/dev/null
      systemctl stop slowdns-iptables &>/dev/null
			print_center -verm2 'fails to start SlowDNS!'
		fi	
	fi
	enter
}

#==========================================

QUIC_SCRIPT(){
	title 'SlowDNS SCRIPT UNINSTALLER'
	read -rp " $(msg -ama "YOU WANT TO UNINSTALL THE SlowDNS SCRIPT [Y/N]?:") " -e -i N UNINS
	[[ $UNINS != @(Y|y) ]] && return
  systemctl disable slowdns &>/dev/null
	systemctl disable slowdns-iptables &>/dev/null
  systemctl stop slowdns &>/dev/null
	systemctl stop slowdns-iptables &>/dev/null
  rm /etc/systemd/system/slowdns.service
	rm /etc/systemd/system/slowdns-iptables.service
	rm /usr/bin/slowdns
	rm -rf $slow_file
	title 'COMPLETE UNINSTALL'
	time_reboot 10
}

DATA_C(){
  DOMAIN_NS="$(cat $slow_file/domain_ns)"
  KEY="$(cat $slow_file/server.pub)"
  title 'CONNECTION DATA'
  echo "$(msg -ama 'Domain:') $(msg -verd "$DOMAIN_NS")"
  msg -bar3
  echo "$(msg -ama 'KEY:') $(msg -verd "$KEY")"
  enter
}

menu_udp(){
	title "slowDNS configuration script BY @Rufu99"
  
	if [[ $(type -p dns-server) ]]; then
    print_center -ama "Ports: 53 5300"
    msg -bar3
    ram=$(printf '%-8s' "$(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }')")
    cpu=$(printf '%-1s' "$(top -bn1 | awk '/Cpu/ { cpu = "" 100 - $8 "%" }; END { print cpu }')")
    echo "   $(msg -verd 'IP:') $(msg -azu "$ip_publica")  $(msg -verd 'Ram:') $(msg -azu "$ram") $(msg -verd 'CPU:') $(msg -azu "$cpu")"
    msg -bar
		if [[ $(systemctl is-active slowdns) = 'active' ]]; then
			estado="\e[1m\e[32m[ON]"
		else
			estado="\e[1m\e[31m[OFF]"
		fi
		echo " $(msg -verd "[1]") $(msg -verm2 '>') $(msg -verm2 "DESINSTALAR slowDNS")"
		echo -e " $(msg -verd "[2]") $(msg -verm2 '>') $(msg -azu "INICIAR/DETENER SlowDNS") $estado"
    echo " $(msg -verd "[3]") $(msg -verm2 '>') $(msg -azu "REOMOVER SCRIPT")"
    msg -bar3
    echo " $(msg -verd "[4]") $(msg -verm2 '>') $(msg -azu "CONNECTION DATA")"
    msg -bar3
		echo " $(msg -verd "[5]") $(msg -verm2 '>') $(msg -verd "CREATE CUSTOMER")"
		echo " $(msg -verd "[6]") $(msg -verm2 '>') $(msg -verm2 "REMOVE CLIENT")"
		echo " $(msg -verd "[7]") $(msg -verm2 '>') $(msg -ama "RENEW CLIENT")"
		echo " $(msg -verd "[8]") $(msg -verm2 '>') $(msg -azu "LOCK/UNLOCK CLIENT")"
		echo " $(msg -verd "[9]") $(msg -verm2 '>') $(msg -blu "CUSTOMER DETAILS")"
		echo " $(msg -verd "[10]") $(msg -verm2 '>') $(msg -azu "LIMITED ACCOUNTS")"
    num=10 ; a=x; b=1
	else
		echo " $(msg -verd "[1]") $(msg -verm2 '>') $(msg -verd "INSTALL SlowDNS")"
		num=1; a=1; b=x
	fi
	back
	opcion=$(selection_fun $num)

	case $opcion in
		$a)install_slow;;
		$b)uninstall_slow;;
		2)reset;;
    3)QUIC_SCRIPT;;
    4)DATA_C;;
		5)new_user;;
		6)remove_user;;
		7)renew_user;;
		8)block_user;;
		9)detail_user;;
		10)limiter;;
		0)return 1;;
	esac
}

while [[  $? -eq 0 ]]; do
  menu_udp
done