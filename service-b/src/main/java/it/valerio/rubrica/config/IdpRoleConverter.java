package it.valerio.rubrica.config;

import org.springframework.core.convert.converter.Converter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

public class IdpRoleConverter implements Converter<Jwt, Collection<GrantedAuthority>> {

    private final Collection<String> roleClaimPaths;
    private final String authorityPrefix;

    public IdpRoleConverter(Collection<String> roleClaimPaths, String authorityPrefix) {
        this.roleClaimPaths = roleClaimPaths;
        this.authorityPrefix = authorityPrefix;
    }

    @Override
    public Collection<GrantedAuthority> convert(Jwt jwt) {
        Set<String> roles = new HashSet<>();

        for (String path : roleClaimPaths) {
            for (Object value : resolvePath(jwt.getClaims(), path)) {
                collectRoles(value, roles);
            }
        }

        return roles.stream()
                .map(String::trim)
                .filter(role -> !role.isBlank())
                .map(role -> role.startsWith(authorityPrefix) ? role : authorityPrefix + role)
                .map(SimpleGrantedAuthority::new)
                .map(GrantedAuthority.class::cast)
                .toList();
    }

    private Collection<Object> resolvePath(Map<String, Object> claims, String path) {
        Collection<Object> current = new ArrayList<>();
        current.add(claims);

        for (String token : path.split("\\.")) {
            Collection<Object> next = new ArrayList<>();
            for (Object item : current) {
                if ("*".equals(token)) {
                    if (item instanceof Map<?, ?> map) {
                        next.addAll(map.values());
                    } else if (item instanceof Collection<?> collection) {
                        next.addAll(collection);
                    }
                } else if (item instanceof Map<?, ?> map) {
                    Object value = map.get(token);
                    if (value != null) {
                        next.add(value);
                    }
                }
            }
            current = next;
        }

        return current;
    }

    private void collectRoles(Object source, Set<String> roles) {
        if (source instanceof String roleText) {
            if (roleText.contains(" ")) {
                for (String token : roleText.split("\\s+")) {
                    if (!token.isBlank()) {
                        roles.add(token);
                    }
                }
            } else {
                roles.add(roleText);
            }
            return;
        }

        if (source instanceof Collection<?> collection) {
            collection.forEach(item -> collectRoles(item, roles));
            return;
        }

        if (source instanceof Map<?, ?> map) {
            map.values().forEach(value -> collectRoles(value, roles));
        }
    }
}
