//
//  main.m
//  Arm64
//
//  Created by Blacktea on 2017/7/16.
//  Copyright © 2017年 Blacktea. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

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

