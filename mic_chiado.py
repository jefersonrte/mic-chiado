"""Mic Chiado - emite ruido branco para um cabo de audio virtual (VB-CABLE).

Fluxo: este app toca chiado em "CABLE Input"; o Windows enxerga isso como o
microfone "CABLE Output". Com ele definido como microfone padrao, qualquer app
que use o microfone padrao ouve apenas chiado.
"""
import os
import sys
import tkinter as tk
import webbrowser
from tkinter import messagebox, ttk

import numpy as np

try:
    import sounddevice as sd
except Exception as exc:  # PortAudio ausente / pacote nao instalado
    sd = None
    SD_ERROR = exc

SAMPLE_RATE = 48000
CABLE_URL = "https://vb-audio.com/Cable/"


class NoiseEngine:
    """Gera ruido branco e o envia para um dispositivo de saida."""

    def __init__(self):
        self.volume = 0.3
        self._stream = None
        self._rng = np.random.default_rng()

    @property
    def running(self):
        return self._stream is not None

    def _callback(self, outdata, frames, time_info, status):
        outdata[:] = self._rng.uniform(-1.0, 1.0, outdata.shape).astype(np.float32) * self.volume

    def start(self, device_index):
        if self.running:
            return
        self._stream = sd.OutputStream(
            device=device_index,
            samplerate=SAMPLE_RATE,
            channels=2,
            dtype="float32",
            callback=self._callback,
        )
        self._stream.start()

    def stop(self):
        if self._stream is not None:
            self._stream.stop()
            self._stream.close()
            self._stream = None


def list_output_devices():
    """Retorna [(indice, rotulo)], priorizando WASAPI e o VB-CABLE."""
    hostapis = sd.query_hostapis()
    found = []
    for idx, dev in enumerate(sd.query_devices()):
        if dev["max_output_channels"] < 2:
            continue
        api = hostapis[dev["hostapi"]]["name"]
        found.append((idx, f'{dev["name"]}  [{api}]', "CABLE Input" in dev["name"], "WASAPI" in api))
    found.sort(key=lambda d: (not d[2], not d[3]))
    return [(i, label) for i, label, _, _ in found], any(d[2] for d in found)


class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Mic Chiado")
        self.resizable(False, False)
        self.engine = NoiseEngine()
        self.devices, has_cable = list_output_devices()

        pad = {"padx": 16, "pady": 6}
        ttk.Label(self, text="Saida do chiado (use CABLE Input):").pack(anchor="w", **pad)
        self.combo = ttk.Combobox(self, state="readonly", width=56,
                                  values=[label for _, label in self.devices])
        if self.devices:
            self.combo.current(0)
        self.combo.pack(**pad)

        ttk.Label(self, text="Volume do chiado:").pack(anchor="w", **pad)
        self.slider = ttk.Scale(self, from_=0.0, to=1.0, value=0.3, length=360,
                                command=self._on_volume)
        self.slider.pack(**pad)

        self.button = tk.Button(self, text="LIGAR", font=("Segoe UI", 16, "bold"),
                                width=14, height=2, bg="#2e7d32", fg="white",
                                command=self.toggle)
        self.button.pack(pady=12)

        self.status = ttk.Label(self, text="Desligado")
        self.status.pack()

        row = ttk.Frame(self)
        row.pack(pady=10)
        ttk.Button(row, text="Abrir configuracoes de som",
                   command=self.open_sound_settings).pack(side="left", padx=4)
        ttk.Button(row, text="Baixar VB-CABLE",
                   command=lambda: webbrowser.open(CABLE_URL)).pack(side="left", padx=4)

        self.protocol("WM_DELETE_WINDOW", self.on_close)
        if not has_cable:
            self.after(300, self.warn_no_cable)

    def warn_no_cable(self):
        messagebox.showwarning(
            "VB-CABLE nao encontrado",
            "Instale o VB-CABLE (gratis) e reinicie o Windows e este app.\n\n"
            "Sem ele o chiado sai pelas caixas de som, e nao pelo microfone.")

    def _on_volume(self, value):
        self.engine.volume = float(value)

    def toggle(self):
        if self.engine.running:
            self.engine.stop()
            self.button.config(text="LIGAR", bg="#2e7d32")
            self.status.config(text="Desligado")
            return
        if not self.devices:
            messagebox.showerror("Erro", "Nenhum dispositivo de saida encontrado.")
            return
        device_index = self.devices[self.combo.current()][0]
        try:
            self.engine.start(device_index)
        except Exception as exc:
            messagebox.showerror("Erro ao abrir o dispositivo", str(exc))
            return
        self.button.config(text="DESLIGAR", bg="#c62828")
        self.status.config(text="Chiando... defina CABLE Output como microfone padrao")

    def open_sound_settings(self):
        if sys.platform == "win32":
            os.startfile("ms-settings:sound")
        else:
            messagebox.showinfo("Info", "Disponivel apenas no Windows.")

    def on_close(self):
        self.engine.stop()
        self.destroy()


def main():
    if sd is None:
        messagebox.showerror("Dependencia ausente",
                             f"Nao foi possivel carregar o sounddevice:\n{SD_ERROR}")
        return
    App().mainloop()


if __name__ == "__main__":
    main()
