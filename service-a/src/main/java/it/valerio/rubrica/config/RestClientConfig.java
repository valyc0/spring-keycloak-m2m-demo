package it.valerio.rubrica.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.oauth2.client.OAuth2AuthorizeRequest;
import org.springframework.security.oauth2.client.OAuth2AuthorizedClient;
import org.springframework.security.oauth2.client.OAuth2AuthorizedClientManager;
import org.springframework.web.client.RestClient;

@Configuration
public class RestClientConfig {

    @Bean
    RestClient.Builder restClientBuilder(
            OAuth2AuthorizedClientManager authorizedClientManager,
            @Value("${app.security.oauth2.client-registration-id}") String clientRegistrationId,
            @Value("${app.security.oauth2.principal:service-a}") String principal) {
        return RestClient.builder()
                .requestInterceptor((request, body, execution) -> {
                    OAuth2AuthorizeRequest authorizeRequest = OAuth2AuthorizeRequest
                            .withClientRegistrationId(clientRegistrationId)
                            .principal(principal)
                            .build();

                    OAuth2AuthorizedClient authorizedClient = authorizedClientManager.authorize(authorizeRequest);
                    if (authorizedClient == null || authorizedClient.getAccessToken() == null) {
                        throw new IllegalStateException("Impossibile ottenere access token da Keycloak");
                    }

                    request.getHeaders().setBearerAuth(authorizedClient.getAccessToken().getTokenValue());
                    return execution.execute(request, body);
                });
    }
}
