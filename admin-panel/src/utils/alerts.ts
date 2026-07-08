import Swal from 'sweetalert2';

/**
 * Returns a configured SweetAlert2 instance styled dynamically to match 
 * the current theme (Light or Dark mode) of the Admin Panel.
 */
export const getSwal = () => {
  const isDark = document.documentElement.classList.contains('dark');
  return Swal.mixin({
    background: isDark ? '#0f172a' : '#ffffff', // matches bg-panel
    color: isDark ? '#f8fafc' : '#0f172a',       // matches text-text-primary
    customClass: {
      popup: `rounded-3xl border ${isDark ? 'border-slate-800' : 'border-slate-200'} shadow-2xl font-sans p-6`,
      title: 'text-lg font-bold font-sans tracking-tight',
      htmlContainer: `${isDark ? 'text-slate-400' : 'text-slate-500'} text-sm font-sans mt-2`,
      confirmButton: 'rounded-xl bg-emerald-500 text-slate-950 px-5 py-2.5 text-xs font-bold transition-all duration-200 cursor-pointer hover:brightness-110 active:scale-95 shadow-md shadow-emerald-500/10 focus:outline-none mx-1.5',
      cancelButton: 'rounded-xl bg-red-500 text-white px-5 py-2.5 text-xs font-bold transition-all duration-200 cursor-pointer hover:brightness-110 active:scale-95 shadow-md shadow-red-500/10 focus:outline-none mx-1.5',
      denyButton: 'rounded-xl bg-slate-500 text-white px-5 py-2.5 text-xs font-bold transition-all duration-200 cursor-pointer hover:brightness-110 active:scale-95 focus:outline-none mx-1.5'
    },
    buttonsStyling: false
  });
};

/**
 * Shows a premium toast notification in the corner of the screen.
 */
export const showToast = (icon: 'success' | 'error' | 'warning' | 'info', title: string) => {
  const isDark = document.documentElement.classList.contains('dark');
  const Toast = Swal.mixin({
    toast: true,
    position: 'top-end',
    showConfirmButton: false,
    timer: 3000,
    timerProgressBar: true,
    background: isDark ? '#0f172a' : '#ffffff',
    color: isDark ? '#f8fafc' : '#0f172a',
    customClass: {
      popup: `rounded-2xl border ${isDark ? 'border-slate-800' : 'border-slate-200'} shadow-xl p-3`,
      title: 'text-xs font-bold font-sans'
    },
    didOpen: (toast) => {
      toast.addEventListener('mouseenter', Swal.stopTimer);
      toast.addEventListener('mouseleave', Swal.resumeTimer);
    }
  });

  Toast.fire({
    icon,
    title
  });
};
