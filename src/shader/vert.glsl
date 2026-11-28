/*
    Copyright (c) 2024 Anthony J. Thibault
    This software is licensed under the MIT License. See LICENSE for more details.
*/

//
// No lighting at all, solid color
//

#version 410 core

uniform mat4 model_view_proj_mat;

in vec3 position;
in vec4 color;

out vec4 frag_color;

void main(void)
{
  gl_Position = model_view_proj_mat * vec4(position, 1);
  frag_color = color;
}
