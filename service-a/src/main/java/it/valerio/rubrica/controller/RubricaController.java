package it.valerio.rubrica.controller;

import it.valerio.rubrica.dto.RubricaDto;
import it.valerio.rubrica.service.RubricaService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/rubrica")
public class RubricaController {

    private final RubricaService rubricaService;

    public RubricaController(RubricaService rubricaService) {
        this.rubricaService = rubricaService;
    }

    @GetMapping
    public List<RubricaDto> findAll() {
        return rubricaService.findAllFromServiceB();
    }
}