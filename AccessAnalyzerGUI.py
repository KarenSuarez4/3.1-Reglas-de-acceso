import subprocess
import tkinter as tk
from tkinter import scrolledtext, messagebox, filedialog
import os
import sys
import re

class AccessAnalyzerGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Validador de Reglas de Acceso")
        self.root.geometry("800x600")
        self.root.configure(bg="#f0f0f0")

        # Determinar la ruta del analizador
        if getattr(sys, 'frozen', False):
            # Si es ejecutable empaquetado
            base_dir = os.path.dirname(sys.executable)
        else:
            # Si es script normal
            base_dir = os.path.dirname(os.path.abspath(__file__))
        
        # Detectar el sistema operativo para usar el nombre correcto del ejecutable
        if sys.platform.startswith('win'):
            # Intenta primero con .exe, luego sin extensión
            self.analyzer_path = os.path.join(base_dir, "access_analyzer.exe")
            if not os.path.exists(self.analyzer_path):
                self.analyzer_path = os.path.join(base_dir, "access_analyzer")
        else:
            self.analyzer_path = os.path.join(base_dir, "access_analyzer")
        
        # Verificar si el ejecutable existe
        if not os.path.exists(self.analyzer_path):
            messagebox.showwarning("Advertencia", f"No se encontró el ejecutable en {self.analyzer_path}\nAsegúrate de que esté compilado y en el mismo directorio.")
        
        # Área de título
        title_frame = tk.Frame(root, bg="#3498db", padx=10, pady=10)
        title_frame.pack(fill="x")
        
        title_label = tk.Label(title_frame, text="Validador de Reglas de Acceso", 
                              font=("Arial", 16, "bold"), bg="#3498db", fg="white")
        title_label.pack()
        
        # Área de entrada
        input_frame = tk.LabelFrame(root, text="Ingrese la regla de acceso", font=("Arial", 12), 
                                   padx=10, pady=10, bg="#f0f0f0")
        input_frame.pack(fill="both", expand=False, padx=20, pady=10)
        
        self.input_text = scrolledtext.ScrolledText(input_frame, height=5, font=("Consolas", 12))
        self.input_text.pack(fill="both", expand=True)
        
        # Ejemplos predefinidos
        examples_frame = tk.Frame(root, bg="#f0f0f0", padx=10, pady=5)
        examples_frame.pack(fill="x", padx=20)
        
        examples_label = tk.Label(examples_frame, text="Ejemplos:", font=("Arial", 10, "bold"), 
                                 bg="#f0f0f0")
        examples_label.pack(side=tk.LEFT, padx=(0, 10))
        
        examples = [
            "user admin AND hour >= 9 AND hour <= 17",
            "user guest AND NOT resource = 'config.xml'",
            "user operator AND day = 'Monday' OR day = 'Wednesday'",
            "user admin AND resource != 'logs.txt'"
        ]
        
        for i, example in enumerate(examples):
            btn = tk.Button(examples_frame, text=f"Ejemplo {i+1}", 
                           command=lambda ex=example: self.set_example(ex),
                           bg="#dcdde1", padx=5)
            btn.pack(side=tk.LEFT, padx=5, pady=5)
        
        # Añadir ejemplo inválido con botón especial
        bad_example = "resource = 'config.xml' AND user admin"  # Ejemplo con sintaxis inválida
        bad_btn = tk.Button(examples_frame, text="Ejemplo malo", 
                           command=lambda: self.set_example(bad_example),
                           bg="#e74c3c", fg="white", padx=5)
        bad_btn.pack(side=tk.LEFT, padx=5, pady=5)
        
        # Botones para acciones
        actions_frame = tk.Frame(root, bg="#f0f0f0", padx=10, pady=5)
        actions_frame.pack(fill="x", padx=20, pady=10)
        
        analyze_btn = tk.Button(actions_frame, text="Analizar Regla", bg="#2ecc71", fg="white", 
                               command=self.analyze_rule, height=2, font=("Arial", 11, "bold"),
                               padx=20)
        analyze_btn.pack(side=tk.LEFT, padx=5)
        
        clear_btn = tk.Button(actions_frame, text="Limpiar", bg="#e74c3c", fg="white",
                             command=self.clear_all, height=2, font=("Arial", 11),
                             padx=10)
        clear_btn.pack(side=tk.LEFT, padx=5)
        
        # Eliminado el botón de guardar resultados
        
        # Área de resultados
        result_frame = tk.LabelFrame(root, text="Resultado del análisis", font=("Arial", 12), 
                                    padx=10, pady=10, bg="#f0f0f0")
        result_frame.pack(fill="both", expand=True, padx=20, pady=10)
        
        self.result_text = scrolledtext.ScrolledText(result_frame, height=10, font=("Consolas", 12),
                                                   bg="#f8f9fa", wrap="word")
        self.result_text.pack(fill="both", expand=True)
        
        # Atajos de teclado
        self.root.bind('<Control-Return>', lambda e: self.analyze_rule())
        
        # Mensaje de estado
        self.status_label = tk.Label(root, text="Listo", bd=1, relief=tk.SUNKEN, anchor=tk.W,
                                    font=("Arial", 9), bg="#f0f0f0")
        self.status_label.pack(side=tk.BOTTOM, fill=tk.X)

    def set_example(self, example):
        self.input_text.delete(1.0, tk.END)
        self.input_text.insert(tk.END, example)
        self.status_label.config(text=f"Ejemplo cargado: {example[:30]}...")

    def clear_all(self):
        self.input_text.delete(1.0, tk.END)
        self.result_text.delete(1.0, tk.END)
        self.status_label.config(text="Se han limpiado todos los campos")

    # Eliminado el método save_results

    def analyze_rule(self):
        rule = self.input_text.get(1.0, tk.END).strip()
        
        if not rule:
            messagebox.showerror("Error", "Por favor ingrese una regla de acceso para analizar")
            return
        
        # Actualizar estado
        self.status_label.config(text="Analizando regla...")
        self.root.update()
        
        try:
            if not os.path.exists(self.analyzer_path):
                self.result_text.delete(1.0, tk.END)
                self.result_text.insert(tk.END, f"ERROR: No se encuentra el analizador en: {self.analyzer_path}")
                self.status_label.config(text="Error: Analizador no encontrado")
                return
                
            # Método según sistema operativo
            if sys.platform.startswith('win'):
                # Usar WSL para ejecutar el analizador Linux
                temp_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "temp_rule.txt")
                with open(temp_file, "w", encoding="utf-8") as f:
                    f.write(rule)
                
                # Usar wsl para ejecutar el analizador Linux
                process = subprocess.Popen(
                    ["wsl", "./access_analyzer"],  # Ejecuta con WSL
                    stdin=subprocess.PIPE,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                    encoding='utf-8'
                )
                
                stdout, stderr = process.communicate(input=rule)
        
            else:
                # Método para Linux/Mac
                process = subprocess.Popen(
                    [self.analyzer_path],
                    stdin=subprocess.PIPE,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                    encoding='utf-8'
                )
                
                stdout, stderr = process.communicate(input=rule)
        
            # Mostrar resultado
            self.result_text.delete(1.0, tk.END)
            
            if hasattr(process, 'returncode') and process.returncode != 0:
                self.result_text.insert(tk.END, f"AVISO: El analizador terminó con código {process.returncode}\n\n")
            
            # Procesar la salida para quitar el mensaje no deseado
            if stdout:
                # Eliminar el mensaje "📝 Ingrese reglas de acceso (Enter y luego Ctrl+D para terminar):"
                processed_output = re.sub(r'📝 Ingrese reglas de acceso \(Enter y luego Ctrl\+D para terminar\):', '', stdout)
                self.result_text.insert(tk.END, processed_output)
            else:
                self.result_text.insert(tk.END, "El analizador no produjo ninguna salida.")
                
            if stderr:
                self.result_text.insert(tk.END, f"ERRORES:\n{stderr}\n\n")
                
            self.status_label.config(text="Análisis completado")
            
        except Exception as e:
            self.result_text.delete(1.0, tk.END)
            self.result_text.insert(tk.END, f"Error al ejecutar el analizador:\n{str(e)}")
            self.status_label.config(text="Error en la ejecución")

if __name__ == "__main__":
    root = tk.Tk()
    app = AccessAnalyzerGUI(root)
    root.mainloop()