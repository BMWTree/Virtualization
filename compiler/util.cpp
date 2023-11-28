#include <map>
#include <string>
#include <iostream>
#include <sstream>
#include <cassert>
#include <pcap.h>
#include <netinet/ether.h>
#include <netinet/ip.h>
#include <netinet/tcp.h>
#include <netinet/udp.h>
#include "SP.h"

const int IP_OFFSET = 2;

std::string getFlowId(unsigned char* user, const struct pcap_pkthdr* pkthdr, const unsigned char* packet) {
    // 提取 IP 头部信息
    struct ip* ip_header = (struct ip*)(packet + IP_OFFSET);

    // 提取协议类型
    int protocol = ip_header->ip_p;

    // 提取源IP和目标IP
    char src_ip_str[INET_ADDRSTRLEN];
    char dst_ip_str[INET_ADDRSTRLEN];
    inet_ntop(AF_INET, &(ip_header->ip_src), src_ip_str, INET_ADDRSTRLEN);
    inet_ntop(AF_INET, &(ip_header->ip_dst), dst_ip_str, INET_ADDRSTRLEN);

    // 使用字符串流存储提取的信息
    std::ostringstream result;
    result << src_ip_str << ", ";
    result << dst_ip_str << ", ";

    // 根据协议类型提取端口信息
    if (protocol == IPPROTO_TCP) {
        // 提取 TCP 头部信息
        struct tcphdr* tcp_header = (struct tcphdr*)(packet + IP_OFFSET + ip_header->ip_hl * 4);

        // 提取源端口和目标端口
        uint16_t src_port = ntohs(tcp_header->th_sport);
        uint16_t dst_port = ntohs(tcp_header->th_dport);

        result << src_port << ", ";
        result << dst_port << ", ";
        result << "TCP";
    } else if (protocol == IPPROTO_UDP) {
        // 提取 UDP 头部信息
        struct udphdr* udp_header = (struct udphdr*)(packet + IP_OFFSET + ip_header->ip_hl * 4);

        // 提取源端口和目标端口
        uint16_t src_port = ntohs(udp_header->uh_sport);
        uint16_t dst_port = ntohs(udp_header->uh_dport);

        result << src_port << ", ";
        result << dst_port << ", ";
        result << "UDP";
    } else {
        result << "Unsupported protocol";
    }

    return result.str();
}

std::string getSrcIP(unsigned char* user, const struct pcap_pkthdr* pkthdr, const unsigned char* packet) {
    // 提取 IP 头部信息
    struct ip* ip_header = (struct ip*)(packet + IP_OFFSET);

    // 提取协议类型
    int protocol = ip_header->ip_p;

    // 提取源IP
    char src_ip_str[INET_ADDRSTRLEN];
    inet_ntop(AF_INET, &(ip_header->ip_src), src_ip_str, INET_ADDRSTRLEN);

    // 使用字符串流存储提取的信息
    std::ostringstream result;
    result << src_ip_str;

    return result.str();
}

std::string getTraceFileName(std::string inputFileName){
    // 查找 ".output" 的位置
    size_t dotPos = inputFileName.find(".output");

    assert(dotPos != std::string::npos);

    // 用 ".trace" 替换 ".output"
    std::string outputFileName = inputFileName;
    outputFileName.replace(dotPos, 7, ".trace");

    return outputFileName;
}
