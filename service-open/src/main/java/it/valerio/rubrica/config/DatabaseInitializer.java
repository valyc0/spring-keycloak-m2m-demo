package it.valerio.rubrica.config;

import it.valerio.rubrica.model.Rubrica;
import it.valerio.rubrica.repository.RubricaRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class DatabaseInitializer implements CommandLineRunner {

    private final RubricaRepository rubricaRepository;

    public DatabaseInitializer(RubricaRepository rubricaRepository) {
        this.rubricaRepository = rubricaRepository;
    }

    @Override
    public void run(String... args) {
        if (rubricaRepository.count() > 0) {
            return;
        }

        Rubrica mario = new Rubrica();
        mario.setNome("Mario");
        mario.setCognome("Rossi");

        Rubrica luigi = new Rubrica();
        luigi.setNome("Luigi");
        luigi.setCognome("Bianchi");

        Rubrica anna = new Rubrica();
        anna.setNome("Anna");
        anna.setCognome("Verdi");

        rubricaRepository.saveAll(List.of(mario, luigi, anna));
    }
}