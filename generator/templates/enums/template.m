{% include 'copyright.txt' %}

#import "{{name}}.h"
{%- block body %}
{% if add_typedef %}
typedef SDLEnum {{name}} SDL_SWIFT_ENUM;
{% endif -%}
{%- if deprecated %}
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
{%- endif %}
{%- for param in params %}
{%- if param.deprecated %}
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
{%- endif %}
{{ name }} const {{ name }}{{param.name}} = @"{{param.origin}}";
{%- if param.deprecated %}
#pragma clang diagnostic pop
{% endif %}
{%- endfor -%}
{%- if deprecated %}
#pragma clang diagnostic pop
{%- endif %}
{% endblock -%}
