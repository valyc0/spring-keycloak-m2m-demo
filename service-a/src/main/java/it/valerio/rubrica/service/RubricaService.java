package it.valerio.rubrica.service;

import it.valerio.rubrica.dto.RubricaDto;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestClient;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class RubricaService {

    private final RestClient restClient;

    public RubricaService(RestClient.Builder restClientBuilder,
                          @Value("${service-b.base-url}") String serviceBBaseUrl) {
        this.restClient = restClientBuilder
                .baseUrl(serviceBBaseUrl)
                .build();
    }

    public List<RubricaDto> findAllFromServiceB() {
        try {
            return restClient.get()
                    .uri("/api/rubrica")
                    .retrieve()
                    .body(new ParameterizedTypeReference<>() {
                    });
        } catch (HttpClientErrorException exception) {
            throw new ResponseStatusException(exception.getStatusCode(), "Chiamata a service-b fallita", exception);
        }
    }
}