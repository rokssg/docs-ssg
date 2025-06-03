import { Button } from '@openfun/cunningham-react';
import { useRef, useEffect } from 'react';
import { t } from 'i18next';
import { useRouter } from 'next/navigation';
import { PropsWithChildren, useCallback, useState } from 'react';
import { ModalAddTypeDoc } from '@/features/docs/doc-management/components/ModalAddTypeDoc';


import { Box, Icon, SeparatedSection } from '@/components';
import { useCreateDoc } from '@/docs/doc-management';
import { useCreateDocFromTemplate } from '@/docs/doc-management';
import { DocSearchModal } from '@/docs/doc-search';
import { useAuth } from '@/features/auth';
import { useCmdK } from '@/hook/useCmdK';

import { useLeftPanelStore } from '../stores';

export const LeftPanelHeader = ({ children }: PropsWithChildren) => {
  const router = useRouter();
  const { authenticated } = useAuth();
  const [isSearchModalOpen, setIsSearchModalOpen] = useState(false);

  const openSearchModal = useCallback(() => {
    const isEditorToolbarOpen =
      document.getElementsByClassName('bn-formatting-toolbar').length > 0;
    if (isEditorToolbarOpen) {
      return;
    }

    setIsSearchModalOpen(true);
  }, []);

 // Split button dropdown state
  const [isDropdownOpen, setDropdownOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);


  const closeSearchModal = useCallback(() => {
    setIsSearchModalOpen(false);
  }, []);

  useCmdK(openSearchModal);
  const { togglePanel } = useLeftPanelStore();

  const { mutate: createDoc, isPending: isCreatingDoc } = useCreateDoc({
    onSuccess: (doc) => {
      router.push(`/docs/${doc.id}`);
      togglePanel();
    },
  });

  const { mutate: createDocFromTemplate, isPending: isCreatingDocTempl } = useCreateDocFromTemplate({
    onSuccess: (doc) => {
      router.push(`/docs/${doc.id}`);
      togglePanel();
    },
  });

  const goToHome = () => {
    router.push('/');
    togglePanel();
  };

  const createNewDoc = () => {
    createDoc();
  };

  const createNewDocFromTemplate = (templateId: string) => {
    createDocFromTemplate({ templateId });
  };

  const [isAddTypeModalOpen, setAddTypeModalOpen] = useState(false);
  // Example: Replace with your actual templates fetching logic
  const templates = getTemplate(() => {
                      const fetchTemplates = async () => {
                        try {
                          const response = await fetch('/api/v1.0/templates/'); // Adjust the endpoint if necessary
                          if (!response.ok) {
                            throw new Error('Failed to fetch templates');
                          }
                          const data = await response.json();
                          setTemplates(data);
                        } catch (error) {
                          console.error('Error fetching templates:', error);
                        }
                      };

                      fetchTemplates();
                    }, []);

  const openAddTypeModal = () => setAddTypeModalOpen(true);
  const closeAddTypeModal = () => setAddTypeModalOpen(false);

  const handleConfirmCreateDoc = (templateId: string) => {
    createDocFromTemplate({ templateId }); // Pass templateId to your mutation if supported
    setAddTypeModalOpen(false);
  };

  // Close dropdown when clicking outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setDropdownOpen(false);
      }
    }
    if (isDropdownOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isDropdownOpen]);

  return (
    <>
      <Box $width="100%" className="--docs--left-panel-header">
        <SeparatedSection>
          <Box
            $padding={{ horizontal: 'sm' }}
            $width="100%"
            $direction="row"
            $justify="space-between"
            $align="center"
          >
            <Box $direction="row" $gap="2px">
              <Button
                onClick={goToHome}
                size="medium"
                color="tertiary-text"
                icon={
                  <Icon $variation="800" $theme="primary" iconName="house" />
                }
              />
              {authenticated && (
                <Button
                  onClick={openSearchModal}
                  size="medium"
                  color="tertiary-text"
                  icon={
                    <Icon $variation="800" $theme="primary" iconName="search" />
                  }
                />
              )}
            </Box>
            {authenticated && (
              <div
                style={{
                  position: 'relative',
                  display: 'flex',
                  alignItems: 'stretch', // Ensures both buttons have the same height
                }}
                ref={dropdownRef}
              >
                <Button
                  onClick={createNewDoc}
                  disabled={isCreatingDoc||isCreatingDocTempl}
                  style={{
                    borderTopRightRadius: 0,
                    borderBottomRightRadius: 0,
                    // Remove explicit height
                  }}
                >
                  {t('New doc')}
                </Button>
                <Button
                  onClick={() => setDropdownOpen((open) => !open)}
                  disabled={isCreatingDoc||isCreatingDocTempl}
                  style={{
                    borderTopLeftRadius: 0,
                    borderBottomLeftRadius: 0,
                    borderLeft: 'none',
                    width: '2.5em',
                    padding: 0,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    // Remove explicit height
                  }}
                  aria-label={t('More options')}
                >
                  <Icon iconName="arrow_drop_down" 
                   style={{ color: '#F3F3F2' }}/>
                </Button>
                {isDropdownOpen && (
                  <div
                    style={{
                      position: 'absolute',
                      right: 0,
                      top: '100%',
                      background: 'white',
                      border: '1px solid #ccc',
                      zIndex: 10,
                      minWidth: '120px',
                      boxShadow: '0 2px 8px rgba(0,0,0,0.15)',
                    }}
                  >
                    <Button
                      onClick={() => {
                        openAddTypeModal();
                        setDropdownOpen(false);
                      }}
                      disabled={isCreatingDoc||isCreatingDocTempl}
                      style={{ width: '100%', justifyContent: 'flex-start' }}
                    >
                      {t('New from template')}
                    </Button>
                  </div>
                )}
              </div>
            )}
          </Box>
          <ModalAddTypeDoc
            isOpen={isAddTypeModalOpen}
            onClose={closeAddTypeModal}
            onConfirm={handleConfirmCreateDoc}
            templates={templates}
          />
        </SeparatedSection>
        {children}
      </Box>
      {isSearchModalOpen && (
        <DocSearchModal onClose={closeSearchModal} isOpen={isSearchModalOpen} />
      )}
    </>
  );
};
