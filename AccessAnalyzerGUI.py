import subprocess
import tkinter as tk
from tkinter import scrolledtext, messagebox, filedialog
import os
import sys
import re

class AccessAnalyzerGUI:
    """
    Clase que implementa una interfaz gráfica para validar reglas de acceso.
    Permite al usuario ingresar reglas de control de acceso y verificar su validez.
    """
    
    def __init__(self, root):
        """
        Inicializa la aplicación y configura la interfaz gráfica principal.
        
        Args:
            root: Ventana principal de la aplicación tkinter.
        """
        self.root = root
        self.root.title("Validador de Reglas de Acceso")
        self.root.geometry("800x600")
        self.root.configure(bg="#f0f0f0")

        if getattr(sys, 'frozen', False):
            base_dir = os.path.dirname(sys.executable)
        else:
            base_dir = os.path.dirname(os.path.abspath(__file__))
        
        if sys.platform.startswith('win'):
            self.analyzer_path = os.path.join(base_dir, "access_analyzer.exe")
            if not os.path.exists(self.analyzer_path):
                self.analyzer_path = os.path.join(base_dir, "access_analyzer")
        else:
            self.analyzer_path = os.path.join(base_dir, "access_analyzer")
        
        if not os.path.exists(self.analyzer_path):
            messagebox.showwarning("Advertencia", f"No se encontró el ejecutable en {self.analyzer_path}\nAsegúrate de que esté compilado y en el mismo directorio.")
        
        title_frame = tk.Frame(root, bg="#3498db", padx=10, pady=10)
        title_frame.pack(fill="x")
        
        title_label = tk.Label(title_frame, text="Validador de Reglas de Acceso", 
                              font=("Arial", 16, "bold"), bg="#3498db", fg="white")
        title_label.pack()
        
        input_frame = tk.LabelFrame(root, text="Ingrese la regla de acceso", font=("Arial", 12), 
                                   padx=10, pady=10, bg="#f0f0f0")
        input_frame.pack(fill="both", expand=False, padx=20, pady=10)
        
        self.input_text = scrolledtext.ScrolledText(input_frame, height=5, font=("Consolas", 12))
        self.input_text.pack(fill="both", expand=True)
        
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
        
        bad_example = "resource = 'config.xml' AND user admin"
        bad_btn = tk.Button(examples_frame, text="Ejemplo malo", 
                           command=lambda: self.set_example(bad_example),
                           bg="#e74c3c", fg="white", padx=5)
        bad_btn.pack(side=tk.LEFT, padx=5, pady=5)
        
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
        
        result_frame = tk.LabelFrame(root, text="Resultado del análisis", font=("Arial", 12), 
                                    padx=10, pady=10, bg="#f0f0f0")
        result_frame.pack(fill="both", expand=True, padx=20, pady=10)
        
        self.result_text = scrolledtext.ScrolledText(result_frame, height=10, font=("Consolas", 12),
                                                   bg="#f8f9fa", wrap="word")
        self.result_text.pack(fill="both", expand=True)
        
        self.root.bind('<Control-Return>', lambda e: self.analyze_rule())
        
        self.status_label = tk.Label(root, text="Listo", bd=1, relief=tk.SUNKEN, anchor=tk.W,
                                    font=("Arial", 9), bg="#f0f0f0")
        self.status_label.pack(side=tk.BOTTOM, fill=tk.X)

    def set_example(self, example):
        """
        Carga un ejemplo predefinido de regla de acceso en el área de entrada.
        
        Args:
            example: Texto del ejemplo a cargar en el campo de entrada.
        """
        self.input_text.delete(1.0, tk.END)
        self.input_text.insert(tk.END, example)
        self.status_label.config(text=f"Ejemplo cargado: {example[:30]}...")

    def clear_all(self):
        """
        Limpia todos los campos de texto de la interfaz.
        Restablece el área de entrada y el área de resultados.
        """
        self.input_text.delete(1.0, tk.END)
        self.result_text.delete(1.0, tk.END)
        self.status_label.config(text="Se han limpiado todos los campos")

    def analyze_rule(self):
        """
        Analiza la regla de acceso ingresada por el usuario.
        
        Envía la regla al analizador externo y muestra los resultados.
        Maneja diferentes sistemas operativos y posibles errores.
        """
        rule = self.input_text.get(1.0, tk.END).strip()
        
        if not rule:
            messagebox.showerror("Error", "Por favor ingrese una regla de acceso para analizar")
            return
        
        self.status_label.config(text="Analizando regla...")
        self.root.update()
        
        try:
            if not os.path.exists(self.analyzer_path):
                self.result_text.delete(1.0, tk.END)
                self.result_text.insert(tk.END, f"ERROR: No se encuentra el analizador en: {self.analyzer_path}")
                self.status_label.config(text="Error: Analizador no encontrado")
                return
                
            if sys.platform.startswith('win'):
                temp_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "temp_rule.txt")
                with open(temp_file, "w", encoding="utf-8") as f:
                    f.write(rule)
                
                process = subprocess.Popen(
                    ["wsl", "./access_analyzer"],
                    stdin=subprocess.PIPE,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                    encoding='utf-8'
                )
                
                stdout, stderr = process.communicate(input=rule)
        
            else:
                process = subprocess.Popen(
                    [self.analyzer_path],
                    stdin=subprocess.PIPE,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                    encoding='utf-8'
                )
                
                stdout, stderr = process.communicate(input=rule)
        
            self.result_text.delete(1.0, tk.END)
            
            if hasattr(process, 'returncode') and process.returncode != 0:
                self.result_text.insert(tk.END, f"AVISO: El analizador terminó con código {process.returncode}\n\n")
            
            if stdout:
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