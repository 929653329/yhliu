#include <iostream>
#include <cstdio>
#include <string>
#include <cstring>
#include <map>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>
#include <stdlib.h>
#include <arpa/inet.h>

using namespace std;
#define PORT 9997

string read_system(string& commond)
{
	FILE* f_linux;
	char chr_linux[65535] = { 0 };
	//read commond
	f_linux = popen(commond.c_str(),"r");
	fread(chr_linux,1,sizeof(chr_linux),f_linux);
	pclose(f_linux);
	
	commond = chr_linux;
	
	return commond;
}

int main()
{
	
	int server_socket = socket(AF_INET, SOCK_STREAM, 0);
	if(server_socket == -1)
	{
			perror("socket create error!\n");
			return -1;
	}
	struct sockaddr_in addr;
	memset(&addr, 0, sizeof(addr));
	addr.sin_family = AF_INET;
  addr.sin_port = htons(PORT);
  addr.sin_addr.s_addr = htonl(INADDR_ANY);
  
  // 设置套接字选项避免地址使用错误  
  int on=1;  
  if((setsockopt(server_socket,SOL_SOCKET,SO_REUSEADDR,&on,sizeof(on)))<0)  
  {  
      perror("setsockopt error!\n");
      return -1;
  }
  
  //服务端与socket绑定
  int ret = bind(server_socket, (struct sockaddr *)&addr, sizeof(addr));
	if(ret == -1)
	{
			perror("bind error!\n");
			return -1;
	}
	//监听
	ret = listen(server_socket, 5);        
	if(ret == -1)
	{
			perror("listen error!\n");
			return -1;
	}
	
	while(1)
	{
			//创建一个新的addr
			struct sockaddr_in client_addr;
			int len_addr = sizeof(client_addr);
			printf("*********wait client***********\n");
			
			//得到一个新的socket
			int client_socket = accept(server_socket, (struct sockaddr *)&client_addr, (socklen_t*)&len_addr);
			if(client_socket == -1)
			{
					perror("accept error!\n");
					close(client_socket);
					continue;
			}
			
			while(1)
			{
				char recv_buf[1024] = { 0 };
				int len = recv(client_socket,recv_buf,1024,0);
				if(len <= 0)
				{
						perror("recv长度小于等于0\n");
						close(client_socket);
						break;
				}
				
				printf("**********from client[%s]*************\n",inet_ntoa(client_addr.sin_addr));
				printf("len:[%d]\n",len);
				printf("buff:[%s]\n",recv_buf);
				
				string str_recvbuf = recv_buf;
				
				if(str_recvbuf == "recv")
				{
						string send_buff = "";
						string str_tmp_1 = "perl linux.pl";
						
						send_buff = read_system(str_tmp_1);
						
						printf("************send to [%s]************\n",inet_ntoa(client_addr.sin_addr));
						printf("send :[%s]\n",send_buff.c_str());
						printf("send len:[%d]\n",send_buff.size());
						send(client_socket, send_buff.c_str(), send_buff.size()+1, 0);
				}
			}
	}
	return 0;
}






