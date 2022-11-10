
install_depend() {
   for i in "wget python dmidecode unzip  ntpdate"
   do
     rpm -q $i &> /dev/null || yum install $i -y 
   done
   
}


sync_time(){
    /usr/sbin/ntpdate -u pool.ntp.org  || true
    ! grep -q "/usr/sbin/ntpdate -u pool.ntp.org" /var/spool/cron/root > /dev/null 2>&1 && echo '*/10 * * * * /usr/sbin/ntpdate -u pool.ntp.org > /dev/null 2>&1 || (date_str=`curl -s update.cdnwaf.cn/common/datetime` && timedatectl set-ntp false && echo $date_str && timedatectl set-time "$date_str" )' >> /var/spool/cron/root
    service crond restart  2>/dev/null

    # 时区
    rm -f /etc/localtime
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

    if /sbin/hwclock -w;then
        return
    fi
    

}




# 开始安装
tar xf ${WORD_DIR}/cdnfly-master-v5.1.13-centos-7.tar.gz  -C /opt && cd /opt && rm -rf cdnfly
mv cdnfly-master-v5.1.13 cdnfly && cd /opt/cdnfly/master


# 安装mysql
install_mysql() {
    rpm -q mariadb-server &> /dev/null || yum install mariadb-server -y 
    my_cnf_path="/etc/my.cnf"
    if [[ ! -f "$my_cnf_path" ]];then
      my_cnf_path="/etc/my.cnf.d/server.cnf"
    fi

    if [[ `grep max_allowed_packet $my_cnf_path` == "" ]];then
        sed -i '/\[mysqld\]/amax_allowed_packet=10M' $my_cnf_path
        sed -i '/\[mysqld\]/a\bind-address=127.0.0.1' $my_cnf_path
        sed -i '/\[mysqld\]/a\max_connections=1000' $my_cnf_path
    fi
    systemctl start mariadb   
    systemctl enable mariadb  2>/dev/null

    /usr/bin/mysqladmin -u root password '@cdnflypass' 
    mysql -uroot -p@cdnflypass -e "CREATE DATABASE cdn CHARSET=UTF8;"  
    mysql -uroot -p@cdnflypass -e 'grant all privileges on *.* to "root"@"127.0.0.1" identified by "@cdnflypass"'   
    mysql -uroot -p@cdnflypass -e "grant all privileges on *.* to \"root\"@\"$MA_IP\" identified by '@cdnflypass'"  
    mysql -uroot -p@cdnflypass -e 'grant all privileges on *.* to "root"@"localhost" identified by "@cdnflypass"'   
    
}



# 安装pip模块
install_pip_module() {
    \cp -rp ${WORD_DIR}/epel.repo /etc/yum.repos.d/

    sed -i 's#https://#http://#g' /etc/yum.repos.d/epel*repo
    yum --enablerepo=epel install python-pip gcc python-devel mariadb-devel libffi-devel -y  || true
    if [[ `yum list installed | grep python2-pip` == "" ]]; then
        sed -i 's#mirrors.aliyun.com#mirrors.tuna.tsinghua.edu.cn#' /etc/yum.repos.d/epel.repo
        yum --enablerepo=epel install python-pip gcc python-devel mariadb-devel libffi-devel -y 
    fi



    cd ${WORD_DIR}
    tar xf pymodule-master-20211219.tar.gz
    cd pymodule-master-20211219

    # 系统环境安装
    ## pip
    pip install pip-20.1.1-py2.py3-none-any.whl 
    ## setuptools
    pip install setuptools-30.1.0-py2.py3-none-any.whl 
    ## supervisor
    pip install supervisor-4.2.0-py2.py3-none-any.whl 
    ## virtualenv
    pip install configparser-4.0.2-py2.py3-none-any.whl 
    pip install scandir-1.10.0.tar.gz 
    pip install typing-3.7.4.1-py2-none-any.whl  
    pip install contextlib2-0.6.0.post1-py2.py3-none-any.whl  
    pip install zipp-1.2.0-py2.py3-none-any.whl  
    pip install six-1.15.0-py2.py3-none-any.whl  
    pip install singledispatch-3.4.0.3-py2.py3-none-any.whl  
    pip install distlib-0.3.0.zip 
    pip install pathlib2-2.3.5-py2.py3-none-any.whl  
    pip install importlib_metadata-1.6.1-py2.py3-none-any.whl  
    pip install appdirs-1.4.4-py2.py3-none-any.whl  
    pip install filelock-3.0.12.tar.gz 
    pip install importlib_resources-2.0.1-py2.py3-none-any.whl  
    pip install virtualenv-20.0.25-py2.py3-none-any.whl  

    # 创建虚拟环境
    cd /opt
    python -m virtualenv -vv --extra-search-dir ${WORD_DIR}/pymodule-master-20211219 --no-download --no-periodic-update venv   
    ## 激活环境
    source /opt/venv/bin/activate

    # 虚拟环境安装
    cd ${WORD_DIR}/pymodule-master-20211219

    ## Flask
    pip install click-7.1.2-py2.py3-none-any.whl  
    pip install itsdangerous-1.1.0-py2.py3-none-any.whl  
    pip install Werkzeug-1.0.1-py2.py3-none-any.whl  
    pip install MarkupSafe-1.1.1-cp27-cp27mu-manylinux1_x86_64.whl  
    pip install Jinja2-2.11.2-py2.py3-none-any.whl  
    pip install Flask-1.1.1-py2.py3-none-any.whl  
    ## PyMySQL
    pip install PyMySQL-0.9.3-py2.py3-none-any.whl  
    ## Pillow
    pip install Pillow-6.2.2-cp27-cp27mu-manylinux1_x86_64.whl   
    ## pycryptodome
    pip install pycryptodome-3.9.7-cp27-cp27mu-manylinux1_x86_64.whl  
    ## bcrypt
    pip install pycparser-2.20-py2.py3-none-any.whl  
    pip install cffi-1.14.0-cp27-cp27mu-manylinux1_x86_64.whl   
    pip install six-1.15.0-py2.py3-none-any.whl  
    pip install bcrypt-3.1.7-cp27-cp27mu-manylinux1_x86_64.whl  
    ## pyOpenSSL
    pip install ipaddress-1.0.23-py2.py3-none-any.whl  
    pip install enum34-1.1.10-py2-none-any.whl  
    pip install cryptography-2.9.2-cp27-cp27mu-manylinux2010_x86_64.whl   
    pip install pyOpenSSL-19.1.0-py2.py3-none-any.whl  
    ## python_dateutil
    pip install python_dateutil-2.8.1-py2.py3-none-any.whl  
    ## aliyun-python-sdk-core
    pip install jmespath-0.10.0-py2.py3-none-any.whl  
    pip install aliyun-python-sdk-core-2.13.19.tar.gz  
    ## aliyun-python-sdk-alidns
    pip install aliyun-python-sdk-alidns-2.0.18.tar.gz  
    ## qcloudapi-sdk-python
    pip install qcloudapi-sdk-python-2.0.15.tar.gz  
    ## requests
    pip install certifi-2020.4.5.2-py2.py3-none-any.whl  
    pip install idna-2.9-py2.py3-none-any.whl  
    pip install chardet-3.0.4-py2.py3-none-any.whl  
    pip install urllib3-1.25.9-py2.py3-none-any.whl  
    pip install requests-2.24.0-py2.py3-none-any.whl  
    pip install forcediphttpsadapter-1.0.2.tar.gz   

    ## psutil
    pip install psutil-5.7.0.tar.gz  
    ## dnspython
    pip install dnspython-1.16.0-py2.py3-none-any.whl  
    ## Flask-Compress
    pip install Brotli-1.0.7-cp27-cp27mu-manylinux1_x86_64.whl   
    pip install Flask-Compress-1.5.0.tar.gz  
    ## supervisor
    pip install supervisor-4.2.0-py2.py3-none-any.whl  
    ## APScheduler
    pip install funcsigs-1.0.2-py2.py3-none-any.whl  
    pip install futures-3.3.0-py2-none-any.whl  
    pip install pytz-2020.1-py2.py3-none-any.whl  
    pip install tzlocal-2.1-py2.py3-none-any.whl  
    pip install APScheduler-3.6.3-py2.py3-none-any.whl  
    ## gunicorn
    pip install gunicorn-19.10.0-py2.py3-none-any.whl  
    ## gevent
    pip install zope.event-4.4-py2.py3-none-any.whl  
    pip install greenlet-0.4.16-cp27-cp27mu-manylinux1_x86_64.whl  
    pip install zope.interface-5.1.0-cp27-cp27mu-manylinux2010_x86_64.whl  
    pip install gevent-20.6.2-cp27-cp27mu-manylinux2010_x86_64.whl  
    ## python_daemon
    pip install docutils-0.16-py2.py3-none-any.whl  
    pip install lockfile-0.12.2-py2.py3-none-any.whl  
    pip install python_daemon-2.2.4-py2.py3-none-any.whl  

    ## weixin-python
    pip install lxml-4.5.2-cp27-cp27mu-manylinux1_x86_64.whl   
    pip install weixin-python-0.5.7.tar.gz   

    ## alipay-sdk-python
    pip install pyasn1-0.4.8-py2.py3-none-any.whl  
    pip install rsa-4.5-py2.py3-none-any.whl  
    pip install pycrypto-2.6.1.tar.gz  
    pip install alipay-sdk-python-3.3.398.tar.gz   

    deactivate
}




install_acme() {
    if [[ ! -d "/root/.acme.sh/" ]]; then
        for i in "unzip  openssl ca-certificates"
        do
          rpm -q $i &> /dev/null || yum install $i -y 
        done

        cd ${WORD_DIR}
        unzip acme.sh-3.0.1.zip
        cd acme.sh-3.0.1
        ./acme.sh --install --nocron  
        cd  /root/.acme.sh/dnsapi
        ln -s /opt/cdnfly/master/conf/dnsdun.sh
    fi
    

}





config() {
    sed -i "s/localhost/$MYSQL_IP/" /opt/cdnfly/master/conf/config.py
    sed -i "s/192.168.0.30/$MA_IP/" /opt/cdnfly/master/conf/config.py
    sed -i "s#ES_PWD#$ES_PASS#" /opt/cdnfly/master/conf/config.py
    rnd=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16`
    sed -i "s/69294a1afed3f1f4/$rnd/" /opt/cdnfly/master/conf/config.py
    kernel_tune
}




install_es() {
   while [ ! -f "/etc/elasticsearch/elasticsearch.yml" ]; do
       yum -y install https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.6.1-x86_64.rpm
   done

if [[ -f "/etc/elasticsearch/elasticsearch.yml" ]]; then
    cat >> /etc/elasticsearch/elasticsearch.yml <<EOF
network.host: 0.0.0.0
node.name: "node-1"
cluster.initial_master_nodes: ["node-1"]
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
EOF

# 设置es目录
sed -i "s#path.data.*#path.data: $ES_DIR#g" /etc/elasticsearch/elasticsearch.yml
mkdir -p $ES_DIR
chown -R elasticsearch $ES_DIR

sed -i '/Service/a\TimeoutSec=600' /usr/lib/systemd/system/elasticsearch.service
systemctl daemon-reload         2>/dev/null
systemctl enable elasticsearch  2>/dev/null

# 配置heap_size
sed -i "s/^-Xms.*/-Xms${HEAP_SIZE}m/" /etc/elasticsearch/jvm.options
sed -i "s/^-Xmx.*/-Xmx${HEAP_SIZE}m/" /etc/elasticsearch/jvm.options


# 设置密码
echo $ES_PASS | /usr/share/elasticsearch/bin/elasticsearch-keystore add -xf bootstrap.password
service elasticsearch start   2>/dev/null
sleep 5
curl -s -H "Content-Type:application/json" -XPOST -u elastic:$ES_PASS 'http://127.0.0.1:9200/_xpack/security/user/elastic/_password' -d "{ \"password\" : \"$ES_PASS\" }"

curl -s -u elastic:$ES_PASS -X PUT "localhost:9200/_ilm/policy/access_log_policy" -H 'Content-Type: application/json' -d'
{
  "policy": {
    "phases": {
      "hot": {
        "actions": {
          "rollover": {
            "max_size": "200gb",
            "max_age": "1d"
          }
        }
      },
      "delete": {
        "min_age": "7d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
' 

curl -s -u elastic:$ES_PASS  -X PUT "localhost:9200/_ilm/policy/node_log_policy" -H 'Content-Type: application/json' -d'
{
  "policy": {
    "phases": {
      "hot": {
        "actions": {
          "rollover": {
            "max_age": "1d"
          }
        }
      },
      "delete": {
        "min_age": "7d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
'  

curl -s -u elastic:$ES_PASS  -X PUT "localhost:9200/_template/http_access_template" -H 'Content-Type: application/json' -d'
{
  "mappings": {
    "properties": {
      "nid":    { "type": "keyword" },
      "uid":    { "type": "keyword" },
      "upid":    { "type": "keyword" },
      "time":   { "type": "date"  ,"format":"dd/MMM/yyyy:HH:mm:ss Z"},
      "addr":  { "type": "keyword"  },
      "method":  { "type": "text" , "index":false },
      "scheme":  { "type": "keyword"  },
      "host":  { "type": "keyword"  },
      "server_port":  { "type": "keyword"  },
      "req_uri":  { "type": "keyword"  },
      "protocol":  { "type": "text" , "index":false },
      "status":  { "type": "keyword"  },
      "bytes_sent":  { "type": "integer"  },
      "referer":  { "type": "keyword"  },
      "user_agent":  { "type": "text" , "index":false },
      "content_type":  { "type": "text" , "index":false },
      "up_resp_time":  { "type": "float" , "index":false,"ignore_malformed": true },
      "cache_status":  { "type": "keyword"  },
      "up_recv":  { "type": "integer", "index":false,"ignore_malformed": true  }
    }
  },
  "index_patterns": ["http_access-*"],
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0,
    "index.lifecycle.name": "access_log_policy",
    "index.lifecycle.rollover_alias": "http_access"
  }
}
'  

curl -s -u elastic:$ES_PASS  -X PUT "localhost:9200/http_access-000001?pretty" -H 'Content-Type: application/json' -d'
{

  "aliases": {
    "http_access":{
      "is_write_index": true
    }
  }
}
'  

curl -s -u elastic:$ES_PASS  -X PUT "localhost:9200/_template/stream_access_template" -H 'Content-Type: application/json' -d'
{
  "mappings": {
    "properties": {
      "nid":    { "type": "keyword" },
      "uid":    { "type": "keyword" },
      "upid":    { "type": "keyword" },
      "port":  { "type": "keyword"  },
      "addr":  { "type": "keyword"  },
      "time":   { "type": "date"  ,"format":"dd/MMM/yyyy:HH:mm:ss Z"},
      "status":  { "type": "keyword"  },
      "bytes_sent":  { "type": "integer" , "index":false },
      "bytes_received":  { "type": "keyword"  },
      "session_time":  { "type": "integer" , "index":false }
    }
  },
  "index_patterns": ["stream_access-*"],
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0,
    "index.lifecycle.name": "access_log_policy",
    "index.lifecycle.rollover_alias": "stream_access"
  }
}
'  

curl -s -u elastic:$ES_PASS  -X PUT "localhost:9200/stream_access-000001?pretty" -H 'Content-Type: application/json' -d'
{
  "aliases": {
    "stream_access":{
      "is_write_index": true
    }
  }
}
'  

curl -s -u elastic:$ES_PASS  -X PUT "localhost:9200/_template/bandwidth_template" -H 'Content-Type: application/json' -d'
{
  "mappings": {
    "properties": {
      "time":   { "type": "date"  ,"format":"yyyy-MM-dd HH:mm:ss"},
      "node_id":  { "type": "keyword"  },
      "nic":  { "type": "keyword"  },
      "inbound":  { "type": "long", "index":false  },
      "outbound":  { "type": "long", "index":false  }
    }
  },
  "index_patterns": ["bandwidth-*"],
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0,
    "index.lifecycle.name": "node_log_policy",
    "index.lifecycle.rollover_alias": "bandwidth"
  }
}
'  

curl -s -u elastic:$ES_PASS  -X PUT "localhost:9200/bandwidth-000001?pretty" -H 'Content-Type: application/json' -d'
{
  "aliases": {
    "bandwidth":{
      "is_write_index": true
    }
  }
}
'  

curl -s -u elastic:$ES_PASS  -X PUT "localhost:9200/_template/nginx_status_template" -H 'Content-Type: application/json' -d'
{
  "mappings": {
    "properties": {
      "time":   { "type": "date"  ,"format":"yyyy-MM-dd HH:mm:ss"},
      "node_id":  { "type": "keyword"  },
      "active_conn":  { "type": "integer" , "index":false },
      "reading":  { "type": "integer" , "index":false },
      "writing":  { "type": "integer" , "index":false },
      "waiting":  { "type": "integer" , "index":false }
    }
  },
  "index_patterns": ["nginx_status-*"],
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0,
    "index.lifecycle.name": "node_log_policy",
    "index.lifecycle.rollover_alias": "nginx_status"
  }
}
'  

curl -s -u elastic:$ES_PASS  -X PUT "localhost:9200/nginx_status-000001?pretty" -H 'Content-Type: application/json' -d'
{
  "aliases": {
    "nginx_status":{
      "is_write_index": true
    }
  }
}
'  

curl -s -u elastic:$ES_PASS  -X PUT "localhost:9200/_template/sys_load_template" -H 'Content-Type: application/json' -d'
{
  "mappings": {
    "properties": {
      "time":   { "type": "date"  ,"format":"yyyy-MM-dd HH:mm:ss"},
      "node_id":  { "type": "keyword"  },
      "cpu":  { "type": "float" , "index":false },
      "load":  { "type": "float" , "index":false },
      "mem":  { "type": "float" , "index":false }
    }
  },
  "index_patterns": ["sys_load-*"],
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0,
    "index.lifecycle.name": "node_log_policy",
    "index.lifecycle.rollover_alias": "sys_load"
  }
}
'  

curl -s -u elastic:$ES_PASS  -X PUT "localhost:9200/sys_load-000001?pretty" -H 'Content-Type: application/json' -d'
{
  "aliases": {
    "sys_load":{
      "is_write_index": true
    }
  }
}
'  

curl -s -u elastic:$ES_PASS  -X PUT "localhost:9200/_template/disk_usage_template" -H 'Content-Type: application/json' -d'
{
  "mappings": {
    "properties": {
      "time":   { "type": "date"  ,"format":"yyyy-MM-dd HH:mm:ss"},
      "node_id":  { "type": "keyword"  },
      "path":  { "type": "keyword"  },
      "space":  { "type": "float" , "index":false },
      "inode":  { "type": "float" , "index":false }
    }
  },
  "index_patterns": ["disk_usage-*"],
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0,
    "index.lifecycle.name": "node_log_policy",
    "index.lifecycle.rollover_alias": "disk_usage"
  }
}
'  


curl -s -u elastic:$ES_PASS  -X PUT "localhost:9200/disk_usage-000001?pretty" -H 'Content-Type: application/json' -d'
{
  "aliases": {
    "disk_usage":{
      "is_write_index": true
    }
  }
}
' 

curl -s -u elastic:$ES_PASS  -X PUT "localhost:9200/_template/tcp_conn_template" -H 'Content-Type: application/json' -d'
{
  "mappings": {
    "properties": {
      "time":   { "type": "date"  ,"format":"yyyy-MM-dd HH:mm:ss"},
      "node_id":  { "type": "keyword"  },
      "conn":  { "type": "integer" , "index":false }
    }
  },
  "index_patterns": ["tcp_conn-*"],
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0,
    "index.lifecycle.name": "node_log_policy",
    "index.lifecycle.rollover_alias": "tcp_conn"
  }
}
'  

curl -s -u elastic:$ES_PASS  -X PUT "localhost:9200/tcp_conn-000001?pretty" -H 'Content-Type: application/json' -d'
{
  "aliases": {
    "tcp_conn":{
      "is_write_index": true
    }
  }
}
' 

# pipeline nginx_access_pipeline
curl -s -u elastic:$ES_PASS -X PUT "localhost:9200/_ingest/pipeline/nginx_access_pipeline?pretty" -H 'Content-Type: application/json' -d'
{
  "description" : "nginx access pipeline",
  "processors" : [
      {
        "grok": {
          "field": "message",
          "patterns": ["%{DATA:nid}\t%{DATA:uid}\t%{DATA:upid}\t%{DATA:time}\t%{DATA:addr}\t%{DATA:method}\t%{DATA:scheme}\t%{DATA:host}\t%{DATA:server_port}\t%{DATA:req_uri}\t%{DATA:protocol}\t%{DATA:status}\t%{DATA:bytes_sent}\t%{DATA:referer}\t%{DATA:user_agent}\t%{DATA:content_type}\t%{DATA:up_resp_time}\t%{DATA:cache_status}\t%{GREEDYDATA:up_recv}"]
        }
      },
      {
          "remove": {
            "field": "message"
          }
      }
  ]
}
' 

# stream_access_pipeline
curl -s -u elastic:$ES_PASS -X PUT "localhost:9200/_ingest/pipeline/stream_access_pipeline?pretty" -H 'Content-Type: application/json' -d'
{
  "description" : "stream access pipeline",
  "processors" : [
      {
        "grok": {
          "field": "message",
          "patterns": ["%{DATA:nid}\t%{DATA:uid}\t%{DATA:upid}\t%{DATA:port}\t%{DATA:addr}\t%{DATA:time}\t%{DATA:status}\t%{DATA:bytes_sent}\t%{DATA:bytes_received}\t%{GREEDYDATA:session_time}"]
        }
      },
      {
          "remove": {
            "field": "message"
          }
      }
  ]
}
'  

# monitor_pipeline
curl -s -u elastic:$ES_PASS -X PUT "localhost:9200/_ingest/pipeline/monitor_pipeline?pretty" -H 'Content-Type: application/json' -d'
{
  "description" : "monitor pipeline",
  "processors" : [
      {
        "json" : {
          "field" : "message",
          "add_to_root" : true
        }
      },
      {
          "remove": {
            "field": "message"
          }
      }
  ]
}
'  

# black_ip
curl -s -u elastic:$ES_PASS  -X PUT "localhost:9200/black_ip" -H 'Content-Type: application/json' -d'
{
  "mappings": {
    "properties": {
      "site_id":    { "type": "keyword" },
      "ip":    { "type": "keyword" },
      "filter":    { "type": "text" , "index":false },
      "uid":  { "type": "keyword"  },
      "exp":  { "type": "keyword"  },
      "create_at":  { "type": "keyword"  }
    }
  }
}
'  

# white_ip
curl -s -u elastic:$ES_PASS  -X PUT "localhost:9200/white_ip" -H 'Content-Type: application/json' -d'
{
  "mappings": {
    "properties": {
      "site_id":    { "type": "keyword" },
      "ip":    { "type": "keyword" },
      "exp":  { "type": "keyword"  },
      "create_at":  { "type": "keyword"  }
    }
  }
}
'  

# auto_swtich
curl -s -u elastic:$ES_PASS  -X PUT "localhost:9200/auto_switch" -H 'Content-Type: application/json' -d'
{
  "mappings": {
    "properties": {
      "host":  { "type": "text" , "index":false },
      "rule":  { "type": "text" , "index":false },
      "end_at":  { "type": "integer", "index":true }
    }
  }
}
'  

# up_res_usage
curl -s -u elastic:$ES_PASS  -X PUT "localhost:9200/up_res_usage" -H 'Content-Type: application/json' -d'
{
  "mappings": {
    "properties": {
      "upid":    { "type": "keyword" },
      "node_id":    { "type": "keyword" },
      "bandwidth":    { "type": "integer" , "index":false },
      "connection":  { "type": "integer" , "index":false },
      "time": { "type": "keyword" }
    }
  }
}
'  

# up_res_limit
curl -s -u elastic:$ES_PASS  -X PUT "localhost:9200/up_res_limit" -H 'Content-Type: application/json' -d'
{
  "mappings": {
    "properties": {
      "upid":    { "type": "keyword" },
      "node_id":    { "type": "keyword" },
      "bandwidth":    { "type": "integer" , "index":false },
      "connection":  { "type": "integer" , "index":false },
      "expire":  { "type": "keyword" }
    }
  }
}
' 

fi

kernel_tune


}




kernel_tune(){
ulimit -n 65535
ulimit -u 4096
swapoff -a
sysctl -w vm.max_map_count=262144  

if [[ ! `grep -q 65535 /etc/security/limits.conf` ]]; then
  echo "*  -  nofile  65535" >> /etc/security/limits.conf
fi

if [[ ! `grep -q 4096 /etc/security/limits.conf` ]]; then
  echo "*  -  nproc  4096" >> /etc/security/limits.conf
fi

if [[ ! `grep -q max_map_count /etc/sysctl.conf` ]]; then
  echo "vm.max_map_count = 262144" >> /etc/sysctl.conf
fi

sed -i -r 's/(.*swap.*)/#\1/' /etc/fstab

}



start_on_boot(){
    local cmd="$1"
    if [[ -f "/etc/rc.local" ]]; then
        sed -i '/exit 0/d' /etc/rc.local
        if [[ `grep "${cmd}" /etc/rc.local` == "" ]];then
            echo "${cmd}" >> /etc/rc.local
        fi
        chmod +x /etc/rc.local
    fi


    if [[ -f "/etc/rc.d/rc.local" ]]; then
        sed -i '/exit 0/d' /etc/rc.local
        if [[ `grep "${cmd}" /etc/rc.d/rc.local` == "" ]];then
            echo "${cmd}" >> /etc/rc.d/rc.local
        fi
        chmod +x /etc/rc.d/rc.local
    fi
}





start() {
    mkdir -p /var/log/cdnfly/
    start_on_boot "supervisord -c /opt/cdnfly/master/conf/supervisord.conf"

    if ! supervisord -c /opt/cdnfly/master/conf/supervisord.conf > /dev/null 2>&1;then
        supervisorctl -c /opt/cdnfly/master/conf/supervisord.conf reload
    fi

    # 导入mysql
        rpm -q  mariadb &> /dev/null || yum install  mariadb -y  
        systemctl stop firewalld.service || true
        systemctl disable firewalld.service 2&>/dev/null|| true

    # 替换__OPENRESTY_KEY__
    key=`tr -cd '[:alnum:]' </dev/urandom | head -c 32`
    key=${key:0:10}
    sed -i "s/__OPENRESTY_KEY__/$key/" /opt/cdnfly/master/conf/db.sql
    mysql -uroot -p@cdnflypass -h 127.0.0.1 cdn < /opt/cdnfly/master/conf/db.sql

    # 获取授权
    \cp -rp ${WORD_DIR}/api.py /opt/venv/lib/python2.7/site-packages/requests/api.py
    source /opt/venv/bin/activate
    cd /opt/cdnfly/master/view
    ret=`python -c "import util;print util.get_auth_code()" || true`
    [[ $ret == "(True, None)" ]] && echo "ok" >/tmp/.stauts || echo "ok" >/tmp/.stauts


    deactivate

    supervisorctl -c /opt/cdnfly/master/conf/supervisord.conf restart all 2&>/dev/null 
}


install_end() {
    if [ "$(cat /tmp/.stauts)" == "ok" ]; then
       rm -rf $WORD_DIR && rm -rf /opt/es_pwd
       mysql -uroot -p@cdnflypass cdn -e 'update user set password="$2b$12$5OwjDnsfoEihlwyHw51Wgu3/MJaUrwMN8ttPgE1l784GfMZwVxH5e",email="admin@cdnwaf.cc" where id=1'
       mysql -uroot -p@cdnflypass cdn -e 'update user set password="$2b$12$88gyrFHe0tJjhweDBUoTeuoLBULs5PJcc656VT73oPxMWfpS4jPIS",name="cdnwaf",email="cdnwaf@cdnwaf.cc" where id=2'
       echo -e "\niptables enable port: 80 88 443 9200"
       echo "http://$(curl -s -s cip.cc |grep -w 'IP' |awk '{print $NF}')"
       echo "admin  adminAbc12345^"
       echo "cdnwaf cdnwafAbc12345^"
    else
      echo -e "\n主控安装失败!!"
      rm -rf $WORD_DIR && rm -rf /opt/es_pwd && rm -rf /opt/venv
    fi
}



trap 'onCtrlC' INT
function onCtrlC () {
        #捕获CTRL+C，当脚本被ctrl+c的形式终止时同时终止程序的后台进程
        kill -9 ${do_sth_pid} ${progress_pid}
        echo
        echo 'Ctrl+C is captured'
        exit 1
}



progress () {
        #进度条程序
        local main_pid=$1
        local length=20
        local ratio=1
        while [ "$(ps -p ${main_pid} | wc -l)" -ne "1" ] ; do
                mark='>'
                progress_bar=
                for i in $(seq 1 "${length}"); do
                        if [ "$i" -gt "${ratio}" ] ; then
                                mark='-'
                        fi
                        progress_bar="${progress_bar}${mark}"
                done
                printf "执行中 : ${progress_bar}\r" 
                ratio=$((ratio+1))
                #ratio=`expr ${ratio} + 1`
                if [ "${ratio}" -gt "${length}" ] ; then
                        ratio=1
                fi
                sleep 0.1
        done
}


shell_bar () {
       do_sth_pid=$(jobs -p | tail -1)
       
       progress "${do_sth_pid}" &
       progress_pid=$(jobs -p | tail -1)
       
       wait "${do_sth_pid}"
}



####### start install ###########
echo -e "\n安装依赖和时间同步" 
install_depend >/dev/null | tee -a /tmp/cdnwaf.log && sync_time >/dev/null | tee -a /tmp/cdnwaf.log &     
shell_bar && printf "完成 \n"


echo -e "\n安装组件" 
install_mysql >/dev/null | tee -a /tmp/cdnwaf.log && install_es >/dev/null | tee -a /tmp/cdnwaf.log && install_pip_module 2&>/dev/null | tee -a /tmp/cdnwaf.log && install_acme 2&>/dev/null | tee -a /tmp/cdnwaf.log &
shell_bar && printf "完成 \n"

echo -e "\n配置和启动服务" 
config >/dev/null | tee -a /tmp/cdnwaf.log && start | tee -a /tmp/cdnwaf.log &    
shell_bar && printf "完成 \n"

install_end
