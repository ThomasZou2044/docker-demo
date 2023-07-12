package com.align.dockerdemo.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * @author yanzou
 * @version V1.0.0
 * @date 2023/07/10
 * @description
 **/
@RestController
public class DemoController {

    @GetMapping("/demo")
    public String demo(){
        return "Hello World こんちは";
    }
}
