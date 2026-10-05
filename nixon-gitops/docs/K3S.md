
`$ apt install etcd-client jq `

`$ k3s server -- etcdctl endpoint status -w table `

# Ports

  TCP 6443  - K8S API Server
  TCP 2379  - Etcd Client 
  TCP 2380  - Etcd Peer
  UDP 8472  - Flannel
  
  TCP 10250 - Netbird