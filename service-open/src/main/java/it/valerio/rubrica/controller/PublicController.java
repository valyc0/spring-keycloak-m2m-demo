package it.valerio.rubrica.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class PublicController {

    @GetMapping("/hello-myworld")
    public String helloMyworld() {
        return "hello myworld";
    }
}
