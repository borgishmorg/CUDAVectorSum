#include <cuda.h>
#include <cuda_runtime.h>
#include <iostream>
#include <fstream>
#include <thread>
#include <chrono>
#include <atomic>

using namespace std;

int n;
int *a = NULL;
int *b = NULL;
int *c = NULL;
atomic<int> cnt(0);
bool run = false;

__global__ void kernel(int* a, int* b, int*c, int l, int r){
    int i = blockIdx.x*blockDim.x+threadIdx.x;
    if(l <= i && i < r)
        c[i] = a[i] + b[i];
}

void slave(int id){
    cudaSetDevice(id);
    cudaSetDeviceFlags(cudaDeviceMapHost);

    cnt++;

    while(!run) this_thread::sleep_for(chrono::milliseconds(20));

    kernel<<<(n/3+31), 32>>>(a, b, c, n/3*id, n/3*(id+1));
    cudaDeviceSynchronize();
    cnt++;
}

int main(){
    ifstream in("input.txt");
    ofstream out("output.txt");

    thread slave0(slave, 0);
    thread slave1(slave, 1);

    while(cnt != 2) this_thread::sleep_for(chrono::milliseconds(20));
    
    in >> n;
    
    cudaHostAlloc(&a, n*sizeof(int), cudaHostAllocMapped);
    cudaHostAlloc(&b, n*sizeof(int), cudaHostAllocMapped);
    cudaHostAlloc(&c, n*sizeof(int), cudaHostAllocMapped);

    for(int i = 0; i < n ; i++) in >> a[i];
    for(int i = 0; i < n ; i++) in >> b[i];

    run = true;

    for(int i = n/3*2; i < n; i++)
        c[i] = a[i] + b[i];

    if(slave0.joinable())
        slave0.join();
    if(slave1.joinable())
        slave1.join();

    for(int i = 0; i < n; i++)
        out << c[i] << ' ';
    return 0;
}