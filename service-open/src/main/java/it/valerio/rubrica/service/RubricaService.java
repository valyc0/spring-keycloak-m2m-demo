package it.valerio.rubrica.service;

import it.valerio.rubrica.dto.RubricaDto;
import it.valerio.rubrica.model.Rubrica;
import it.valerio.rubrica.repository.RubricaRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class RubricaService {

    private final RubricaRepository rubricaRepository;

    public RubricaService(RubricaRepository rubricaRepository) {
        this.rubricaRepository = rubricaRepository;
    }

    public List<RubricaDto> findAll() {
        return rubricaRepository.findAll()
                .stream()
                .map(this::toDto)
                .toList();
    }

    private RubricaDto toDto(Rubrica rubrica) {
        return new RubricaDto(rubrica.getId(), rubrica.getNome(), rubrica.getCognome());
    }
}