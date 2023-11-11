#!/bin/bash
##########################################
#   呼伦贝尔学院 - 健康打卡 - 自动打卡脚本
#       Another : 0xc0000142
#       Date : 2023.11.11
#       Version : Dev.2
##########################################
load_config() {
    if [ -f "./config.env" ]; then
        source ./config.env
    fi
    USER=1
    while (($USER <= $USER_COUNT)); do
        log "Loading Config config.user${USER}.env"
        env ${USER}
        main
        let USER++
    done
}

env() {
    LOGIN_URL="https://open.hlbec.edu.cn/auth/oauth/login?login_type=normal"
    COOKIE_SID_GET_URL="https://open.hlbec.edu.cn/app.php/hlbec_apps/epidemic_new/index/index?verify_request=e78f4f7c67cc42a60c1901d3249d5de718e15d5d"
    REPORT_URL="https://open.hlbec.edu.cn/app.php/hlbec_apps/epidemic_new/index/report"
    if [ -f "./config.user${1}.env" ]; then
        source config.user${1}.env
    else
        log ERROR "Config Not Exist,Generating...."
        cp config.user.env.exmple config.user${1}.env
        log "Generated Config"
        log "Please Modify Config.env and restart this script"
        exit 1
    fi
    if [[ -z "${USERNAME}" ]]; then
        log ERROR "Config Missing (USERNAME:) in config.user${1}.env  !"
        log ERROR "Please Check Config!"
        exit 1
    fi
    if [[ -z "${LOGIN_DATA}" ]]; then
        log ERROR "Config Missing (LOGIN_DATA:) in config.user${1}.env !"
        log ERROR "Please Check Config!"
        exit 1
    fi

}
login() {
    log "USER=${USER} 尝试登陆"
    wget -q -O - "${LOGIN_URL}" \
        --save-cookies=cookies.txt \
        --header="User-Agent: $USER_AGENT" \
        --post-data "${LOGIN_DATA}" | grep -A1 '<div  style="text-align: center;font-size: 1.25rem;font-weight: bold;color:#4b5563">' | grep '/' | sed 's/ //g' | sed 's/<\/div>//g' | awk -F'/' '{printf "Name=\"%s\"\nID=\"%s\"\n", $1, $2}' > ./temp

    source temp
    rm temp
    USER1="${USER} Name=$Name ID=$ID"
    cat cookies.txt | grep TGC_UID_ENC >/dev/null
    if (($? != 0)); then
        log ERROR "USER=${USER1} 登陆失败！"
        exit 2
    fi

    log "USER=${USER1} 已成功获取 SID:$(cat cookies.txt | grep SID | awk -F' ' '{print $7}')"
}

report() {
    log "USER=${USER1} 开始打卡"
    wget -q "${COOKIE_SID_GET_URL}" \
        --header='Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
        --header='Accept-Language: zh-CN,zh;q=0.9' \
        --header='Cache-Control: no-cache' \
        --header='Connection: keep-alive' \
        --header='DNT: 1' \
        --header='Pragma: no-cache' \
        --header='Sec-Fetch-Dest: document' \
        --header='Sec-Fetch-Mode: navigate' \
        --header='Sec-Fetch-Site: none' \
        --header='Sec-Fetch-User: ?1' \
        --header='Upgrade-Insecure-Requests: 1' \
        --header='sec-ch-ua: " Not A;Brand";v="99", "Chromium";v="102"' \
        --header='sec-ch-ua-mobile: ?0' \
        --header='sec-ch-ua-platform: "Windows"' \
        --load-cookies=cookies.txt \
        --save-cookies=cookies.txt \
        --header="Content-Type: application/json; charset=UTF-8" \
        --header="User-Agent: ${USER_AGENT}" \
        -O /dev/null
    RESULT=$(
        wget -q "${REPORT_URL}" \
            --header='Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
            --header='Accept-Language: zh-CN,zh;q=0.9' \
            --header='Cache-Control: no-cache' \
            --header='Connection: keep-alive' \
            --header='DNT: 1' \
            --header='Pragma: no-cache' \
            --header='Sec-Fetch-Dest: document' \
            --header='Sec-Fetch-Mode: navigate' \
            --header='Sec-Fetch-Site: none' \
            --header='Sec-Fetch-User: ?1' \
            --header='Upgrade-Insecure-Requests: 1' \
            --header='sec-ch-ua: " Not A;Brand";v="99", "Chromium";v="102"' \
            --header='sec-ch-ua-mobile: ?0' \
            --header='sec-ch-ua-platform: "Windows"' \
            --load-cookies=cookies.txt \
            --save-cookies=cookies.txt \
            --header="Content-Type: application/json; charset=UTF-8" \
            --header="User-Agent: ${USER_AGENT}" \
            -O - \
            --post-data "${REPORT_INFO}"
    )
    echo $RESULT | grep true >/dev/null
    if (($? != 0)); then
        log ERROR "USER=${USER1} 打卡失败！ Result: ${RESULT}"
        exit 2
    else
        log "USER=${USER1} 打卡成功！ Result: ${RESULT}"
    fi
    rm cookies.txt
}

log() {
    if [ $# -eq 2 ]; then
        printf "%-5s $(date '+%F %T') $2\n" ${1^^}
    else
        printf "%-5s $(date '+%F %T') $*\n" INFO
    fi
}

main() {
    login
    report
}
load_config
