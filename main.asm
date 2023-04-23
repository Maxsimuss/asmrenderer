%include 'pe.inc'
PE64

; ////////////////////////////////////////////////

IMPORT
	LIB opengl32.dll
		FUNC wglCreateContext
		FUNC wglMakeCurrent
		FUNC wglDeleteContext
		FUNC glViewport
		FUNC glBegin
		FUNC glColor3f
		FUNC glVertex2f
		FUNC glEnd
		FUNC glClearColor
		FUNC glClear
		FUNC glGetError
		FUNC glOrtho
		FUNC glPushMatrix
		FUNC glPopMatrix
	ENDLIB
	LIB glfw3.dll
		FUNC glfwCreateWindow
		FUNC glfwInit
		FUNC glfwSwapBuffers
		FUNC glfwPollEvents
		FUNC glfwWindowShouldClose
		FUNC glfwDestroyWindow
		FUNC glfwTerminate
		FUNC glfwMakeContextCurrent
		FUNC glfwSetWindowSizeCallback
		FUNC glfwGetKey
	ENDLIB
	LIB user32.dll
		FUNC MessageBoxA
	ENDLIB
	LIB Kernel32.dll
		FUNC ExitProcess 
	ENDLIB
ENDIMPORT

; ////////////////////////////////////////////////

WindowWidth: db qword 600
WindowHeight: db qword 800
WindowTitle: db "x86-64 ASM OpenGL Renderer!",0

WindowErr: db "Could not create window!",0
ErrorBuffer: times 64 db 0x00

WindowPtr: db qword 0
RenderContext: db qword 0

ViewportArgs: dd 0.0, 0.0, 20.0, 20.0

VertexPos: dd 0.0, 0.5
Color: dd 1.0, 0.0, 0.0

FrameIndex: db qword 0
Const1000: dd 100.0
Const120: dd 2.0943951
Const240: dd 4.1887902

; ////////////////////////////////////////////////

%macro enter 1
	push rbp
	mov rbp, rsp
	sub rsp, %1
%endmacro

%macro leave 0
	mov rsp, rbp
	pop rbp
%endmacro

%macro ThrowErr 1
	mov rcx, 0
	mov rdx, VA(%1)
	mov r8, VA(%1)
	mov r9, 0x00000010
	call [VA(MessageBoxA)]

	mov rcx, 1
	call [VA(ExitProcess)]
%endmacro

; ////////////////////////////////////////////////

resizeCallback:
	enter 24
		mov r9, r8
		mov r8, rdx
		mov rcx, 0
		mov rdx, 0
		call [VA(glViewport)]
	leave
	ret

START
	enter 32
		; mov rcx, 0
		; call [VA(wglCreateContext)]
		; mov [VA(RenderContext)], rax
		; mov rcx, 0
		; mov rdx, [VA(RenderContext)]
		; call [VA(wglMakeCurrent)]

		call [VA(glfwInit)]

		enter 0
			mov rcx, 800
			mov rdx, 600
			mov r8, VA(WindowTitle)
			mov r9, qword 0
			push qword 0
			call [VA(glfwCreateWindow)]
		leave
		

		test rax, rax
		jnz ._ok
		ThrowErr WindowErr
	._ok:
		mov [VA(WindowPtr)], rax

		mov rcx, [VA(WindowPtr)]
		call [VA(glfwMakeContextCurrent)]

		mov rcx, [VA(WindowPtr)]
		mov rdx, VA(resizeCallback)
		call [VA(glfwSetWindowSizeCallback)]
	_renderLoop:
		inc qword [VA(FrameIndex)]

		fild qword [VA(FrameIndex)]
		fld dword [VA(Const1000)]
		fdivp
		fsin
		fabs
		fstp dword [VA(Color)]

		fild qword [VA(FrameIndex)]
		fld dword [VA(Const1000)]
		fdivp
		fld dword [VA(Const120)]
		faddp
		fsin
		fabs
		fstp dword [VA(Color + 4)]

		fild qword [VA(FrameIndex)]
		fld dword [VA(Const1000)]
		fdivp
		fld dword [VA(Const240)]
		faddp
		fsin
		fabs
		fstp dword [VA(Color + 8)]

		call [VA(glfwPollEvents)]

		mov rcx, [VA(WindowPtr)]
		call [VA(glfwWindowShouldClose)]
		test rax, rax
		jnz _exit

		call [VA(glPushMatrix)]

		; movd xmm0, [VA(ViewportArgs)]
		; movd xmm1, [VA(ViewportArgs + 4)]
		; movd xmm2, [VA(ViewportArgs + 8)]
		; movd xmm3, [VA(ViewportArgs + 12)]
		; push __float64__(0.0)
		; mov rax, __float64__(10.0)
		; push rax
		; call [VA(glOrtho)]
		; call [VA(glGetError)]


		mov rcx, __float32__(0.1)
		movq xmm0, rcx
		mov rdx, __float32__(0.15)
		movq xmm1, rdx
		mov r8, __float32__(0.2)
		movq xmm2, r8
		mov r9, __float32__(1.0)
		movq xmm3, r9
		call [VA(glClearColor)]
		mov rcx, 0x00004000
		call [VA(glClear)]

		mov rcx, [VA(WindowPtr)]
		mov rdx, 87
		call [VA(glfwGetKey)]
		test rax, rax
		jnz skipDraw

		mov rcx, 4
		call [VA(glBegin)]

		movd xmm0, [VA(Color)]
		movd xmm1, [VA(Color + 4)]
		movd xmm2, [VA(Color + 8)]
		call [VA(glColor3f)]

		movd xmm0, [VA(VertexPos)]
		movd xmm1, [VA(VertexPos)]
		call [VA(glVertex2f)]

		movd xmm0, [VA(VertexPos + 4)]
		movd xmm1, [VA(VertexPos)]
		call [VA(glVertex2f)]

		movd xmm0, [VA(VertexPos + 4)]
		movd xmm1, [VA(VertexPos + 4)]
		call [VA(glVertex2f)]

		call [VA(glEnd)]

skipDraw:


		call [VA(glPopMatrix)]

		
		call [VA(glGetError)]
		test rax, rax
		jz ._ok

		add rax, 0x40
		mov [VA(ErrorBuffer)], rax

		ThrowErr ErrorBuffer
	._ok:
		mov rcx, [VA(WindowPtr)]
		call [VA(glfwSwapBuffers)]

		jmp _renderLoop

	_exit:

		mov rcx, [VA(WindowPtr)]
		call [VA(glfwDestroyWindow)]
		call [VA(glfwTerminate)]

		mov rcx, 0
		mov rdx, 0
		call [VA(wglMakeCurrent)]

		mov rcx, [VA(RenderContext)]
		call [VA(wglDeleteContext)]

	leave

	mov rcx, 0
	call [VA(ExitProcess)]

	mov rax, 0
	ret 16
END