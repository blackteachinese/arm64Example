---
title: arm64指令新手教程
categories:
  - default
tags:
  - default
date: 2017-07-12 21:39:27
---


## 什么是栈？
堆栈严格来说应该叫做栈，栈(Stack)是限定仅在一端进行插入或删除操作的线性表。因此，对栈来说，可以进行插入或删除操作的一端端称为栈顶(top)，相应地，另一端称为栈底(bottom)。由于堆栈只允许在一端进行操作，因而按照后进先出（LIFO-Last In First Out）的原理运作。


## 会变化的栈顶
从栈顶的定义来看，栈顶的位置是可变的。空栈时，栈顶和栈底重合；满栈时，栈顶离栈底最远。ARM为堆栈提供了硬件支持，它使用一个专门的寄存器（堆栈指针）指向堆栈的栈顶。

## 两种存储器堆栈
递增堆栈：向上生长：向高地址方向生长
递减堆栈：向下生长：向低地址方向生长
![](https://ws4.sinaimg.cn/large/006tNc79gy1fhlu7dlg1cj30go0750sv.jpg)
## ARM堆栈的生长方向
虽然ARM处理器核对于两种生长方式的堆栈均支持，但ADS的C语言编译器仅支持一种方式，即从上往下长，并且必须是满递减堆栈。所以STMFD等指令用的最多。

## 寄存器

寄存器是用来存储CPU在计算过程中临时数据的, arm64有32个通用寄存器(这里不对浮点数/向量寄存器等做说明):
x0-x31, 这些寄存器可以直接在汇编代码里面使用, 也是最经常被使用到的寄存器.
* SP寄存器, Stack Pointer, 指向栈低的指针. 它是一个隐含的寄存器, 可以在内存操作指令中通过x31寄存器来访问.
* PC寄存器, Program Counter, 记录当前执行的代码的地址. 它是一个隐含的寄存器, 无法被直接访问, 只能被特定的指令隐含访问.
* LR寄存器, Link Register, 指向返回地址, 即return时回到的地址. 它就是x30, 可以随意访问读写, 意味着程序可以随意改变方法的返回地址.
* FP寄存器, Frame Pointer, 指向上一次方法调用的frame的最高位地址, frame位于栈上. 它就是x29, 可以随意访问读写.

FP是指向frame的最高位地址, frame位于栈上, 那frame是什么呢?
frame其实就是一个按照方法调用顺序, 从栈的高地址向低地址依次存放的一组数据, 用于存放上一次方法调用的关键信息. 数据可以参考下图:
![](https://ws1.sinaimg.cn/large/006tNc79gy1fhluegxwbnj30or0jv3zr.jpg)
## 寻址方式

~~~

add x0,x0,#1            ;x0 <==x0+1 ,把x0的内容加1。
add x0,x0,#0x30         ;x0 <==x0+0x30,把x0的内容加 0x30。
add x0,x1,x3            ;x0 <==x1+x3, 把x1的内容加上x3的内容放入x0
add x0,x1,x3,lsl #3     ;x0 <==x0+x3*8 ,x3的值左移3位就是乘以8，结果与x1的值相, 放入x0.
add x0,x1,[x2]          ;x0 <==x1+[x2], 把x1的内容加上x2的内容作为地址取内存内容放入x0
ldr x0,[x1]             ;x0 <==[x1], 把x1的内容作为地址取内存内容放入x0
str x0,[x1]             ;[x1] <== x0, 把x0的内容放入x1的内容作为地址的内存中
ldr x0,[x1,#4]          ;x0 <==[x1+4], 把x1的内容加上4, 作为内存地址, 取其内容放入x0
ldr x0,[x1,#4]!         ;x0 <==[x1+4]、 x1<==x1+4, 把x1的内容加上4, 作为内存地址, 取其内容放入x0, 然后把x1的内容加上4放入x1
ldr x0,[x1],#4          ;x0 <==[x1] 、x1 <==x1+4, 把x1的内容作为内存地址取内存内容放入x0, 并把x1的内容加上4放入x1
ldr x0,[x1,x2]          ;x0 <==[x1+x2], 把x1和x2的内容相加, 作为内存地址取内存内容放入x0

~~~
## 常用指令

b 跳转到地址（无返回）, 不会改变LR寄存器的值
bl 跳转到地址（有返回）, 会改变LR寄存器的值为返回地址
ldr/ldur 地址对应的内容加载到寄存器
str/stur 寄存器内容存储到内存地址
ldp/stp 取/存一对数据(2个)
cbz/cbnz 为零跳转到地址/不为零跳转到
add 加法运算
mov 寄存器之间内容移动
ldp/stp 从栈取/存数据
adrp, 用来定位数据段中的数据用, 因为aslr会导致代码及数据的地址随机化, 用adrp来根据pc做辅助定位

## 案例解析
``main函数汇编解析``
* 设置Debug->Debug Workflow->Always Show Disassembly
* 打断点到callMe函数。PS：callMe调用别的方法才会被保存frame

~~~
void callYou() {
    
}

void callMe(int a, int b) {
    callYou();
}

int main(int argc, char * argv[]) {
    int a = 4;
    int b = 10;
    callMe(a, b);
}

~~~

这段代码编译结果如下

~~~
libdyld.dylib`start:
    0x18aad55b4 <+0>: nop    
    0x18aad55b8 <+4>: bl     0x18ab05378               ; exit
    0x18aad55bc <+8>: brk    #0x3
~~~

~~~
Arm64`main:
    0x100026c24 <+0>:  sub    sp, sp, #0x30             ; =0x30 ;编译器计算到此次方法调用要48bit的栈,把栈底减48bit留出空位存临时变量
    0x100026c28 <+4>:  stp    x29, x30, [sp, #0x20] ;将fp和lr存入栈的sp+32的地址
    0x100026c2c <+8>:  add    x29, sp, #0x20            ; =0x20 ;sp+32后存入x29，fp此时的位置就是sp+32
    0x100026c30 <+12>: mov    w8, #0xa ;将10存到寄存器w8
    0x100026c34 <+16>: orr    w9, wzr, #0x4 ;将4与wzr进行或运算，存到寄存器W9
    0x100026c38 <+20>: stur   w0, [x29, #-0x4] ;把w0(main方法的第一个参数, argc),存入x29减4的位置
    0x100026c3c <+24>: str    x1, [sp, #0x10] ;将x1(main方法的第二个参数*argv[])，存入sp-16的位置
    0x100026c40 <+28>: str    w9, [sp, #0xc] ;将w9的值，存入到sp+12的位置
    0x100026c44 <+32>: str    w8, [sp, #0x8] ;将w8的值，存入到sp+8的位置
    0x100026c48 <+36>: ldr    w0, [sp, #0xc] ;将sp+12地址对应的内容加载到寄存器w0
    0x100026c4c <+40>: ldr    w1, [sp, #0x8] ;将sp+8地址对应的内容加载到寄存器w1
    0x100026c50 <+44>: bl     0x100026c00               ; callMe at main.m:16 ;调用callMe方法,将w0、w1作为参数
->  0x100026c54 <+48>: mov    w8, #0x0 ;将0存到w8
    0x100026c58 <+52>: mov    x0, x8 ;将0存到x0
    0x100026c5c <+56>: ldp    x29, x30, [sp, #0x20] ;从栈里把最开始保存的fp和lr还原回来
    0x100026c60 <+60>: add    sp, sp, #0x30             ; =0x30 ;sp+48后,存到sp(跳到下一个frame的位置)
    0x100026c64 <+64>: ret ;返回
~~~

~~~
Arm64`callMe:
    0x100026c00 <+0>:  sub    sp, sp, #0x20             ; =0x20 ;编译器计算到此次方法调用要用到32bit的栈，把栈底减32bit留出空位存临时变量
    0x100026c04 <+4>:  stp    x29, x30, [sp, #0x10] ;将fp和lr寄存器存入到sp+16的位置
    0x100026c08 <+8>:  add    x29, sp, #0x10            ; =0x10 ; 将sp+16后，存入到x29
    0x100026c0c <+12>: stur   w0, [x29, #-0x4] ; 将w0（第一个参数）存入到x29 -4的位置
    0x100026c10 <+16>: str    w1, [sp, #0x8] ;将w1(第二个参数) 存入到sp+8的位置
->  0x100026c14 <+20>: bl     0x100026bfc               ; callYou at main.m:14 ; 调用callYou方法
    0x100026c18 <+24>: ldp    x29, x30, [sp, #0x10] ;从栈里把最开始保存的fp和lr还原回来
    0x100026c1c <+28>: add    sp, sp, #0x20             ; =0x20 ;sp+32后，存入到sp(跳到下一个frame的位置)
    0x100026c20 <+32>: ret   
~~~
![从start->main->callme->callYou有3个frame](https://ws3.sinaimg.cn/large/006tNc79gy1fhlu8cthldj30yk04uabc.jpg)
## sp的正负偏移

sp存取的时候有的偏移量是正数, 有的是负数, 这有什么区别呢?
在stack里面, sp指针之下(负数偏移量)的数据是不保证安全的, 可能被覆盖, 而sp指针之上(正数偏移量)的数据是安全的. 放到负数偏移量一般都是临时存一下数据, 需要被整个方法用到的数据一般放到sp的正数偏移位置.

## git地址
[demo传送门](https://github.com/blackteachinese/arm64Example)

