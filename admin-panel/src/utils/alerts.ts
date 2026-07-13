import Swal from 'sweetalert2';

/**
 * Returns a configured SweetAlert2 instance styled dynamically to match 
 * the current active theme colors of the Admin Panel from CSS Custom Properties.
 */
export const getSwal = () => {
  const rootStyle = getComputedStyle(document.documentElement);
  
  // Get active theme variables dynamically
  const bgPanel = rootStyle.getPropertyValue('--bg-input').trim() || '#ffffff';
  const textPrimary = rootStyle.getPropertyValue('--text-primary').trim() || '#0f172a';
  const borderCard = rootStyle.getPropertyValue('--border-input').trim() || 'rgba(15, 23, 42, 0.08)';
  const accentPrimary = rootStyle.getPropertyValue('--accent-primary').trim() || '#10b981';
  const textSecondary = rootStyle.getPropertyValue('--text-secondary').trim() || '#475569';

  return Swal.mixin({
    background: bgPanel,
    color: textPrimary,
    customClass: {
      popup: 'rounded-3xl border shadow-2xl font-sans p-6 max-w-sm',
      title: 'text-lg font-bold font-sans tracking-tight',
      htmlContainer: 'text-sm font-sans mt-2',
      input: 'rounded-xl border px-4 py-2.5 text-sm focus:outline-none focus:ring-1 w-full max-w-xs inline-block text-center transition-all m-2',
      confirmButton: 'rounded-xl text-white px-5 py-2.5 text-xs font-bold transition-all duration-200 cursor-pointer hover:brightness-110 active:scale-95 shadow-md focus:outline-none mx-1.5',
      cancelButton: 'rounded-xl bg-red-500 text-white px-5 py-2.5 text-xs font-bold transition-all duration-200 cursor-pointer hover:brightness-110 active:scale-95 shadow-md shadow-red-500/10 focus:outline-none mx-1.5',
      denyButton: 'rounded-xl bg-slate-500 text-white px-5 py-2.5 text-xs font-bold transition-all duration-200 cursor-pointer hover:brightness-110 active:scale-95 focus:outline-none mx-1.5'
    },
    buttonsStyling: false,
    didOpen: (popup) => {
      popup.style.borderColor = borderCard;
      
      const titleEl = popup.querySelector('.swal2-title') as HTMLElement;
      if (titleEl) titleEl.style.color = textPrimary;
      
      const htmlEl = popup.querySelector('.swal2-html-container') as HTMLElement;
      if (htmlEl) htmlEl.style.color = textSecondary;

      const confirmBtn = popup.querySelector('.swal2-confirm') as HTMLElement;
      if (confirmBtn) {
        confirmBtn.style.backgroundColor = accentPrimary;
        confirmBtn.style.boxShadow = `0 4px 12px ${accentPrimary}25`;
      }
      
      const inputEl = popup.querySelector('.swal2-input') as HTMLInputElement | HTMLSelectElement;
      if (inputEl) {
        inputEl.style.backgroundColor = bgPanel;
        inputEl.style.color = textPrimary;
        inputEl.style.borderColor = borderCard;
        inputEl.style.outline = 'none';
        
        // Custom styling for option list options inside select
        const options = inputEl.querySelectorAll('option');
        options.forEach(opt => {
          opt.style.backgroundColor = bgPanel;
          opt.style.color = textPrimary;
        });
      }
    }
  });
};

/**
 * Shows a premium toast notification in the corner of the screen.
 */
export const showToast = (icon: 'success' | 'error' | 'warning' | 'info', title: string) => {
  const rootStyle = getComputedStyle(document.documentElement);
  const bgPanel = rootStyle.getPropertyValue('--bg-input').trim() || '#ffffff';
  const textPrimary = rootStyle.getPropertyValue('--text-primary').trim() || '#0f172a';
  const borderCard = rootStyle.getPropertyValue('--border-input').trim() || 'rgba(15, 23, 42, 0.08)';

  const Toast = Swal.mixin({
    toast: true,
    position: 'top-end',
    showConfirmButton: false,
    timer: 3000,
    timerProgressBar: true,
    background: bgPanel,
    color: textPrimary,
    customClass: {
      popup: 'rounded-2xl border shadow-xl p-3',
      title: 'text-xs font-bold font-sans'
    },
    didOpen: (toast) => {
      toast.style.borderColor = borderCard;
      toast.addEventListener('mouseenter', Swal.stopTimer);
      toast.addEventListener('mouseleave', Swal.resumeTimer);
    }
  });

  Toast.fire({
    icon,
    title
  });
};
